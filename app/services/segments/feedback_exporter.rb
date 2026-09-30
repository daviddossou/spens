# frozen_string_literal: true

# Splits every user created up to +cutoff+ into the three feedback segments:
#   A — nothing entered and dormant
#   B — entered at least one real record, never came back after sign-up day, dormant
#   C — everyone else (came back another day, or active recently); no e-mail
# "Real record" = account, transaction (not opening balances), budget entry, goal or debt authored
# by the user. Budget entries and goals carry no author, so they are attributed to the owner of
# their space; rows without user_id fall back to the space owner too. Read-only.
module Segments
  class FeedbackExporter
    COLUMNS = %w[
      email prenom locale pays date_inscription derniere_activite
      nb_comptes nb_transactions nb_lignes_budget nb_objectifs nb_dettes email_suspect
    ].freeze

    TEST_EMAIL = /test|example\.com|mailinator|@.*\.(test|local|invalid)\z|@localhost/i
    TYPO_DOMAIN = /@(gmial|gmai|gamil|gmal|yaho|yahooo|hotmial|hotmal|outlok|outloo)\./i

    Result = Struct.new(:segments, :report, keyword_init: true)

    def initialize(cutoff:, dormant_days: 14, excluded_emails: [], now: Time.current)
      @cutoff = cutoff
      @dormant_days = dormant_days
      @excluded_emails = excluded_emails.map { |e| e.to_s.downcase.strip }
      @now = now
    end

    def call
      segments = { a: [], b: [], c: [] }
      exclusions = Hash.new(0)
      seen = Set.new
      out_of_scope = User.where("created_at > ?", @cutoff.end_of_day).count

      User.where(created_at: ..@cutoff.end_of_day).order(:created_at).find_each do |user|
        email = user.email.to_s.downcase.strip
        if @excluded_emails.include?(email) then exclusions["adresse exclue"] += 1
        elsif email.match?(TEST_EMAIL) then exclusions["compte de test"] += 1
        elsif !seen.add?(email) then exclusions["doublon"] += 1
        else
          row = build_row(user, email)
          segments[classify(row)] << row
        end
      end

      Result.new(segments: segments, report: report(segments, exclusions, out_of_scope))
    end

    private

    def build_row(user, email)
      owned_ids = user.owned_spaces.pluck(:id)
      space = user.owned_spaces.order(:created_at).first
      counts = {
        "nb_comptes" => authored(Account, user, owned_ids).count,
        "nb_transactions" => real_transactions(user, owned_ids).count,
        "nb_lignes_budget" => BudgetEntry.where(space_id: owned_ids).count,
        "nb_objectifs" => Goal.where(space_id: owned_ids).count,
        "nb_dettes" => authored(Debt, user, owned_ids).count
      }
      last_activity = Users::LastActivityEstimate.call(user)

      {
        "email" => email,
        "prenom" => user.first_name,
        "locale" => space&.locale,
        "pays" => space&.country,
        "date_inscription" => user.created_at.to_date.iso8601,
        "derniere_activite" => last_activity&.to_date&.iso8601,
        "email_suspect" => email.match?(TYPO_DOMAIN) ? "oui" : "non",
        :signed_up_on => user.created_at.to_date,
        :last_activity_at => last_activity
      }.merge(counts)
    end

    def classify(row)
      returned = row[:returned] = row[:last_activity_at].present? && row[:last_activity_at].to_date > row[:signed_up_on]
      dormant = row[:last_activity_at].nil? || row[:last_activity_at] < @now - @dormant_days.days
      return :c if returned || !dormant

      row.values_at("nb_comptes", "nb_transactions", "nb_lignes_budget", "nb_objectifs", "nb_dettes").sum.zero? ? :a : :b
    end

    def authored(model, user, owned_ids)
      Users::LastActivityEstimate.authored(model, user, owned_ids)
    end

    def real_transactions(user, owned_ids)
      authored(Transaction, user, owned_ids).joins(:transaction_type)
        .where.not(transaction_types: { kind: "initial_balance" })
    end

    def report(segments, exclusions, out_of_scope)
      total = segments.values.sum(&:size)
      suspects = segments.values.flatten.count { |r| r["email_suspect"] == "oui" }
      lines = [
        "Périmètre : comptes créés jusqu'au #{@cutoff.iso8601} inclus. Hors périmètre (créés après) : #{out_of_scope}.",
        "Segment A (rien saisi) : #{segments[:a].size}",
        "Segment B (commencé puis parti) : #{segments[:b].size}",
        "Segment C (revenus ou actifs, pas d'e-mail) : #{segments[:c].size}, dont #{segments[:c].count { |r| r[:returned] }} " \
        "revenus un autre jour et #{segments[:c].count { |r| !r[:returned] }} seulement actifs dans les #{@dormant_days} derniers jours",
        "Total : #{total}",
        "Exclusions : #{exclusions.empty? ? 'aucune' : exclusions.map { |k, v| "#{k} #{v}" }.join(', ')}",
        "Adresses suspectes : #{suspects} (faute de frappe sur le domaine ; aucun log de rebond n'existe en base)",
        "Critère d'activité : users.last_active_at (stampé à chaque requête, au plus une fois par heure) ; avant son " \
        "ajout, max(sign-in Devise, confirmation e-mail, dernier push, dernière écriture sur espace/adhésion/compte/" \
        "transaction/budget/objectif/dette ; jamais les envois de push ou de rappels). " \
        "Dormant = aucune activité depuis #{@dormant_days} jours.",
        "Arbitrages : lignes de budget et objectifs n'ont pas d'auteur, attribués au propriétaire de l'espace ; " \
        "comptes/transactions/dettes sans user_id attribués au propriétaire ; soldes de départ non comptés comme transactions."
      ]
      lines.join("\n")
    end
  end
end
