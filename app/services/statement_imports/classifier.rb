# frozen_string_literal: true

module StatementImports
  # Decides the kind of each proposed line from evidence in its own text, never from the model's
  # say-so alone: a transfer needs one of the user's accounts (or their own name) in the text, a
  # debt needs an ongoing debt's name. Without evidence a line falls back to expense/income by its
  # sign; anything uncertain is flagged for review, and the user's correction is what we learn from.
  class Classifier
    CASH_WORDS = %w[retrait gab atm withdrawal cashout].freeze
    CASH_ACCOUNTS = %w[especes espece cash liquide liquidites portemonnaie caisse wallet].freeze
    DEBT_HINTS = /dette|debt|pret|loan|rembours|refund/
    # Words that name a kind of account rather than one account: "MTN MoMo" matches on "mtn"/"momo",
    # never on "money".
    GENERIC = %w[banque bank compte account mobile money carte card mon ma my principal courant epargne
                 savings wallet portefeuille porte monnaie virtuelle virtual prepayee prepaid credit cash].freeze

    # How people name an account vs how the other side labels it ("MoMo" ↔ "PULL MTN BENIN").
    ALIASES = { "momo" => %w[mtn], "mtn" => %w[momo], "flooz" => %w[moov], "moov" => %w[flooz] }.freeze

    def initialize(import)
      @import = import
      @space = import.space
      @user = import.user
    end

    def classify(drafts)
      drafts.each { classify_one(_1) }
    end

    def account_named(text)
      words = words_of(text)
      candidates.find { |account| (significant_words(account.name) & words).any? }
    end

    private

    def classify_one(draft)
      words = words_of("#{draft.label} #{draft.reference}")
      sign = draft.amount.to_d.negative? ? :out : :in
      model_kind = draft.kind
      draft.kind = nil

      if @import.account_id && (account = named_account(words))
        transfer(draft, account, sign, "named_account")
      elsif own_name?(words)
        draft.kind = "transfer"
        draft.needs_review = true
        draft.flag("own_name")
      elsif @import.account_id && sign == :out && cash_withdrawal?(draft, words)
        cash(draft)
      elsif (debt = matching_debt(words))
        draft.kind = sign == :out ? "debt_out" : "debt_in"
        draft.debt_id = debt.id
        draft.flag("debt_name")
      end
      draft.kind ||= fallback(draft, model_kind, sign, words)
    end

    def transfer(draft, account, sign, reason)
      draft.kind = "transfer"
      draft.counterpart_account_id = account.id
      draft.flag(reason)
      draft.flag(sign == :out ? "transfer_out" : "transfer_in")
    end

    def cash(draft)
      draft.flag("cash_withdrawal")
      if (account = cash_account)
        transfer(draft, account, :out, "cash_account")
      else
        draft.kind = "expense"
      end
    end

    def fallback(draft, model_kind, sign, words)
      by_sign = sign == :out ? "expense" : "income"
      case model_kind
      when "transfer"
        draft.needs_review = true
        draft.flag("unbacked_transfer")
      when "debt_in", "debt_out"
        draft.needs_review = true
        draft.flag("unbacked_debt")
      end
      if words.join(" ").match?(DEBT_HINTS)
        draft.needs_review = true
        draft.flag("debt_hint")
      end
      by_sign
    end

    # The merchant line of a USD+XOF pair took over the "RETRAIT" label: a card payment, not cash.
    def cash_withdrawal?(draft, words)
      !draft.flags.include?("label_from_pair") && words.intersect?(CASH_WORDS)
    end

    def named_account(words)
      candidates.reject { cash_account?(_1) }.find { |account| (significant_words(account.name) & words).any? }
    end

    def own_name?(words)
      names = [ @user.first_name, @user.last_name ].map { words_of(_1) }
      names.all?(&:present?) && names.all? { |name| (name & words).any? }
    end

    def matching_debt(words)
      @debts ||= @space.debts.ongoing.to_a
      @debts.find do |debt|
        name = words_of(debt.name)
        name.present? && (name - words).empty?
      end
    end

    def cash_account
      @cash_account ||= candidates.find { cash_account?(_1) }
    end

    def cash_account?(account)
      CASH_ACCOUNTS.include?(CategoryText.normalize(account.name))
    end

    def candidates
      @candidates ||= @space.accounts.active.where.not(id: @import.account_id).to_a
    end

    def significant_words(name)
      words = words_of(name).reject { |w| GENERIC.include?(w) }
      (words + words.flat_map { ALIASES.fetch(_1, []) }).select { _1.length >= 3 }.uniq
    end

    def words_of(text)
      I18n.transliterate(text.to_s).downcase.scan(/[a-z0-9]+/)
    end
  end
end
