# frozen_string_literal: true

# == Schema Information
#
# Table name: statement_import_lines
#
#  id                      :uuid             not null, primary key
#  amount                  :decimal(15, 2)
#  balance                 :decimal(15, 2)
#  capture_index           :integer          not null
#  categorization          :jsonb
#  category_source         :string
#  currency                :string
#  decision                :string           default("pending"), not null
#  extracted               :jsonb            not null
#  fee                     :decimal(15, 2)
#  final                   :jsonb
#  flags                   :jsonb            not null
#  kind                    :string
#  label                   :string
#  needs_review            :boolean          default(FALSE), not null
#  occurred_at             :datetime
#  occurred_on             :date
#  position                :integer          not null
#  reference               :string
#  status                  :string           not null
#  transaction_type_name   :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :uuid             indexed
#  counterpart_account_id  :uuid             indexed
#  created_transaction_id  :uuid             indexed
#  debt_id                 :uuid             indexed
#  duplicate_of_id         :uuid             indexed
#  existing_transaction_id :uuid             indexed
#  statement_import_id     :uuid             not null, indexed
#
# Indexes
#
#  index_statement_import_lines_on_account_id               (account_id)
#  index_statement_import_lines_on_counterpart_account_id   (counterpart_account_id)
#  index_statement_import_lines_on_created_transaction_id   (created_transaction_id)
#  index_statement_import_lines_on_debt_id                  (debt_id)
#  index_statement_import_lines_on_duplicate_of_id          (duplicate_of_id)
#  index_statement_import_lines_on_existing_transaction_id  (existing_transaction_id)
#  index_statement_import_lines_on_statement_import_id      (statement_import_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => nullify
#  fk_rails_...  (counterpart_account_id => accounts.id) ON DELETE => nullify
#  fk_rails_...  (created_transaction_id => transactions.id) ON DELETE => nullify
#  fk_rails_...  (debt_id => debts.id) ON DELETE => nullify
#  fk_rails_...  (duplicate_of_id => statement_import_lines.id) ON DELETE => nullify
#  fk_rails_...  (existing_transaction_id => transactions.id) ON DELETE => nullify
#  fk_rails_...  (statement_import_id => statement_imports.id)
#
# One line read from a capture: the model's raw read (`extracted`), our proposal on the other
# columns, and what the user finally saved (`final`).
class StatementImportLine < ApplicationRecord
  STATUSES = %w[ok declined cancelled pending card_check not_transaction cut_off duplicate].freeze
  DECISIONS = %w[pending accepted skipped].freeze

  belongs_to :statement_import, inverse_of: :lines
  belongs_to :account, optional: true
  belongs_to :counterpart_account, class_name: "Account", optional: true
  belongs_to :debt, optional: true
  belongs_to :duplicate_of, class_name: "StatementImportLine", optional: true
  belongs_to :existing_transaction, class_name: "Transaction", optional: true
  belongs_to :created_transaction, class_name: "Transaction", optional: true

  validates :status, inclusion: { in: STATUSES }
  validates :decision, inclusion: { in: DECISIONS }

  scope :proposed, -> { where(status: "ok", duplicate_of_id: nil) }

  CATEGORY_KINDS = %w[expense income].freeze
  OUT_KINDS = %w[expense debt_out].freeze
  # Why a line is shown under "À vérifier", most important first.
  REVIEW_FLAGS = %w[already_in_spens foreign_currency own_name unbacked_transfer unbacked_debt debt_hint
                    unpaired_duplicate maybe_overlap refund].freeze
  FORM_FIELDS = %w[kind account_name from_account_name to_account_name fee_amount transaction_date
                   transaction_type_name label note contact_name direction].freeze

  def proposed?
    status == "ok" && duplicate_of_id.nil?
  end

  # Shown in the review list: proposed, and not taken out by the user.
  def listed?
    proposed? && !removed?
  end

  # Taken out by the user (swipe, or "Ignorer"): shown under "Ignorées", "retirée par toi".
  def removed?
    flags.include?("removed")
  end

  # Counted and saved by "Enregistrer N transactions".
  def included?
    listed? && decision == "pending"
  end

  # Left out until the user decides: a likely duplicate (until "Garder quand même") or an
  # amount in another currency (until the amount in the space currency is entered).
  def awaiting_decision?
    listed? && !included? && (already_in_spens? || flags.include?("foreign_currency"))
  end

  def already_in_spens?
    flags.include?("already_in_spens") && !flags.include?("kept")
  end

  def category_kind?
    CATEGORY_KINDS.include?(kind)
  end

  # Filed under "Other" because nothing matched: still counted, shown under "À vérifier".
  def fallback_category?
    category_source == "fallback"
  end

  def money_out?
    amount.to_d.negative?
  end

  def transfer?
    kind == "transfer"
  end

  # The first reason this line needs a look, or nil when it can go as it is.
  def review_reason
    return nil unless listed?

    (REVIEW_FLAGS & flags - (already_in_spens? ? [] : [ "already_in_spens" ])).first ||
      ("no_category" if category_kind? && transaction_type_name.blank?) ||
      ("fallback_category" if category_kind? && fallback_category?) ||
      ("uncertain_category" if category_kind? && category_source == "ai") ||
      ("needs_review" if needs_review)
  end

  # Why a line is under "Ignorées": taken out by the user, its status, or how it duplicates another.
  def ignored_reason
    return "removed" if removed?
    return nil if proposed?
    return status unless %w[ok duplicate].include?(status)

    (%w[fee_row same_event overlap same_reference] & flags).first || "duplicate"
  end

  # A set-aside line the user can bring back into the list.
  def addable?
    return true if removed?

    !proposed? && amount.present? && !amount.zero? && !flags.include?("fee_row")
  end

  # Back into the list. A line the user chose to add is kept even if it looks like a duplicate;
  # an amount in another currency still waits for the amount in the space currency.
  def restore!
    foreign = flags.include?("foreign_currency")
    update!(status: "ok", duplicate_of: nil, decision: foreign ? "skipped" : "pending",
            flags: (flags - [ "removed" ]) | [ "restored", ("kept" if flags.include?("already_in_spens")) ].compact)
  end

  # Swiped away or "Ignorer": out of the list and the totals, recoverable with "Ajouter".
  def remove!
    update!(decision: "skipped", flags: flags | [ "removed" ])
  end

  # "Garder quand même" on a likely duplicate.
  def keep!
    update!(decision: "pending", flags: flags | [ "kept" ])
  end

  # What saving this line sends to TransactionForm: the user's own edit when there is one. The
  # text read on the statement is the note, so the user rewords it there and the list titles the
  # row with it.
  def payload
    base = final.presence || generated_payload
    base.merge("transaction_type_name" => transaction_type_name.presence || base["transaction_type_name"]).compact_blank
  end

  # The user edited the line in the transaction form: keep their version, and mirror it on the
  # columns the list shows.
  def apply_form!(form)
    out = form.transfer? ? form.from_account_name.to_s.casecmp?(account&.name.to_s) : OUT_KINDS.include?(form.kind)
    self.final = form.attributes.slice(*FORM_FIELDS).transform_values { _1.is_a?(Date) ? _1.iso8601 : _1&.to_s }
                     .merge("amount" => form.amount.to_s, "debt_id" => form.debt_id).compact_blank
    self.kind = form.kind
    self.amount = out ? -form.amount : form.amount
    self.fee = form.fee_amount
    self.occurred_on = form.transaction_date
    self.label = form.note.presence || label
    self.transaction_type_name = form.transaction_type_name
    self.category_source = "user"
    self.currency = statement_import.space.currency
    self.flags = (flags - %w[foreign_currency]) | [ "edited" ]
    self.needs_review = false
    self.decision = "pending"
    save!
  end

  private

  def generated_payload
    base = { "kind" => kind, "amount" => amount.abs.to_s, "fee_amount" => fee&.to_s,
             "transaction_date" => (occurred_on || Date.current).iso8601, "note" => label,
             "account_name" => account&.name, "debt_id" => debt_id }
    return base unless kind == "transfer"

    from, to = money_out? ? [ account, counterpart_account ] : [ counterpart_account, account ]
    base.merge("from_account_name" => from&.name, "to_account_name" => to&.name)
  end
end
