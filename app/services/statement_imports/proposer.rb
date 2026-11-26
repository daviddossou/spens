# frozen_string_literal: true

module StatementImports
  # Turns the raw reads of an import into lines: our own deterministic fixes on top of what the
  # model saw (thousands read as decimals, fee rows, the same movement notified twice, captures
  # that overlap), then the Classifier's kind, then a check against what is already in Spens.
  # Every guess is a proposal the user confirms; nothing here locks a line.
  class Proposer
    ZERO_DECIMAL = %w[XOF XAF GNF KMF RWF UGX BIF DJF XPF JPY KRW VND CLP PYG].freeze
    FEE_LABEL = /\b(frais|fees?|commissions?|charges?)\b/i
    LONG_NUMBER = /\d{6,}/

    Draft = Struct.new(:capture_index, :position, :status, :kind, :amount, :fee, :currency, :occurred_on,
                       :occurred_at, :label, :reference, :balance, :account_id, :counterpart_account_id,
                       :debt_id, :needs_review, :flags, :duplicate_of, :existing_transaction_id, :extracted,
                       keyword_init: true) do
      def proposed? = status == "ok" && duplicate_of.nil?

      def flag(name)
        flags << name unless flags.include?(name)
      end

      def tokens = "#{label} #{reference}".scan(LONG_NUMBER)
    end

    def self.call(import)
      new(import).call
    end

    def initialize(import)
      @import = import
      @space = import.space
      @zone = ActiveSupport::TimeZone[import.user.time_zone.to_s] || Time.zone
    end

    def call
      @import.account ||= guess_account
      drafts = build_drafts
      fold_fee_rows(drafts)
      pair_duplicates(drafts)
      dedupe(drafts)
      dedupe_same_day(drafts)
      Classifier.new(@import).classify(drafts.select(&:proposed?))
      flag_existing(drafts.select(&:proposed?))
      persist(drafts)
    end

    private

    def build_drafts
      position = 0
      @import.reads.flat_map do |read|
        Array(read.dig("result", "lines")).map do |raw|
          draft_for(raw, read["capture_index"].to_i, position += 1)
        end
      end
    end

    def draft_for(raw, capture_index, position)
      currency = raw["currency"].to_s.upcase.presence || @space.currency
      draft = Draft.new(
        capture_index: capture_index, position: position, extracted: raw, flags: [],
        status: StatementImportLine::STATUSES.include?(raw["status"]) ? raw["status"] : "not_transaction",
        kind: raw["kind"], currency: currency, label: raw["label"].to_s.strip.presence,
        reference: raw["reference"].to_s.strip.presence, needs_review: raw["needs_review"] == true,
        account_id: @import.account_id
      )
      draft.amount = money(raw["amount"], currency, draft)
      draft.fee = money(raw["fee"], currency, draft)&.abs
      draft.balance = money(raw["balance"], currency, draft)
      draft.occurred_on, draft.occurred_at = parse_date(raw["date"])
      if draft.status == "ok" && draft.amount.to_d.zero?
        draft.status = "not_transaction"
        draft.flag("no_amount")
      end
      draft.flag("foreign_currency") if draft.status == "ok" && currency != @space.currency
      draft
    end

    # "100.005" on a XOF line is 100 005: the model read a thousands separator as a decimal.
    def money(value, currency, draft)
      return nil if value.nil?

      amount = value.to_d
      if ZERO_DECIMAL.include?(currency) && amount.frac.nonzero?
        scaled = amount * 1000
        if scaled.frac.zero?
          draft.flag("thousands_separator")
          return scaled
        end
      end
      amount.round(2)
    end

    def parse_date(value)
      text = value.to_s.strip
      return [ nil, nil ] unless text.match?(/\A\d{4}-\d{2}-\d{2}/)

      day = Date.iso8601(text[0, 10])
      at = text.length > 10 ? @zone.parse(text) : nil
      [ day, at ]
    rescue ArgumentError
      [ nil, nil ]
    end

    # A PDF lists the fee as its own row naming the same operation number: fold it into that line.
    # Numbers shared by many rows (a terminal id, the account number) identify nothing.
    def fold_fee_rows(drafts)
      drafts.group_by(&:capture_index).each_value do |rows|
        counts = rows.flat_map { _1.tokens.uniq }.tally
        rows.each do |row|
          next unless row.proposed? && row.label.to_s.match?(FEE_LABEL) && row.amount.to_d.negative?

          own = row.tokens.select { counts[_1] <= 2 }
          parent = rows.find do |d|
            d != row && d.proposed? && !d.label.to_s.match?(FEE_LABEL) && d.tokens.intersect?(own) &&
              (d.occurred_on.nil? || row.occurred_on.nil? || (d.occurred_on - row.occurred_on).abs <= 3)
          end
          next unless parent

          parent.fee = parent.fee.to_d + row.amount.abs
          parent.flag("fee_merged")
          row.duplicate_of = parent
          row.flag("fee_row")
        end
      end
    end

    # A card payment abroad is notified twice: in USD with the merchant, then in XOF as a bare
    # "RETRAIT". Keep the space-currency amount with the merchant name. The model marks one of them
    # as a duplicate; when it does not, we pair them by time (the bank clocks can differ by an hour).
    # Two lines in the same currency are two real movements, never a pair.
    def pair_duplicates(drafts)
      drafts.each do |d|
        next unless d.status == "duplicate" && d.duplicate_of.nil?

        if (partner = pair_for(d, drafts))
          pair(d, partner)
        else
          d.status = "ok"
          d.needs_review = true
          d.flag("unpaired_duplicate")
        end
      end
      drafts.select { _1.proposed? && _1.currency != @space.currency }.each do |foreign|
        partner = pair_for(foreign, drafts, within: 70.minutes)
        pair(foreign, partner) if partner
      end
    end

    def pair_for(line, drafts, within: nil)
      drafts.find do |d|
        next false unless d != line && d.proposed? && d.capture_index == line.capture_index && d.currency != line.currency
        next d.balance == line.balance if d.balance && line.balance
        next d.occurred_at && line.occurred_at && (d.occurred_at - line.occurred_at).abs <= within if within

        d.occurred_on.nil? || line.occurred_on.nil? || d.occurred_on == line.occurred_on
      end
    end

    def pair(a, b)
      keep, drop = a.currency == @space.currency ? [ a, b ] : [ b, a ]
      keep.status = "ok"
      keep.flags.delete("foreign_currency")
      mark_duplicate(drop, keep, "same_event")
      return if drop.label.blank?

      keep.label = drop.label
      keep.flag("label_from_pair")
    end

    # Overlapping captures, or the SMS and the statement of one account, list a movement twice.
    def dedupe(drafts)
      kept = []
      drafts.select(&:proposed?).each do |d|
        original = kept.find { same_reference?(_1, d) }
        reason = "same_reference" if original
        original ||= kept.find { overlap?(_1, d) }
        unless original
          kept << d
          next
        end

        # Keep the richer notice (a statement row carries the fee and the reference).
        keep, drop = richness(d) > richness(original) ? [ d, original ] : [ original, d ]
        kept[kept.index(original)] = keep
        keep.fee ||= drop.fee
        mark_duplicate(drop, keep, reason || "overlap")
      end
    end

    # Apps that show only the date (no time) repeat the lines where two captures overlap. Same day,
    # amount and label: the line counts as many times as it shows on ONE capture, so two real
    # identical purchases visible together stay two, while the copy on the next capture goes.
    # Same day and amount under another label, on another capture, is only flagged.
    def dedupe_same_day(drafts)
      dated = drafts.select { _1.proposed? && _1.occurred_on && _1.occurred_at.nil? }
      dated.group_by { [ _1.occurred_on, _1.amount.abs, CategoryText.normalize(_1.label) ] }.each_value do |same|
        per_capture = same.group_by(&:capture_index)
        next if per_capture.size < 2

        keep = per_capture.values.max_by(&:size)
        (same - keep).each_with_index { |d, i| mark_duplicate(d, keep[i % keep.size], "overlap") }
      end
      dated = dated.select(&:proposed?)
      dated.group_by { [ _1.occurred_on, _1.amount.abs ] }.each_value do |same|
        next if same.map(&:capture_index).uniq.size < 2 || same.map { CategoryText.normalize(_1.label) }.uniq.size < 2

        same.each { _1.flag("maybe_overlap") }
      end
    end

    def same_reference?(a, b)
      ref = ->(d) { d.reference.to_s.gsub(/[^[:alnum:]]/, "").downcase }
      ref[a].length >= 6 && ref[a] == ref[b] && a.amount.abs == b.amount.abs
    end

    # Same minute and money on another capture (the app shows fees folded into the amount),
    # unless each carries its own, different operation number.
    def overlap?(a, b)
      return false if a.capture_index == b.capture_index || a.occurred_at.nil? || b.occurred_at.nil?
      return false unless a.occurred_at.change(sec: 0) == b.occurred_at.change(sec: 0)
      return false if a.tokens.any? && b.tokens.any? && !a.tokens.intersect?(b.tokens)

      x, y = a.amount.abs, b.amount.abs
      x == y || x == y + b.fee.to_d || y == x + a.fee.to_d
    end

    def richness(draft)
      [ draft.fee, draft.reference, draft.occurred_at ].count(&:present?)
    end

    def mark_duplicate(draft, original, reason)
      draft.status = "duplicate"
      draft.duplicate_of = original
      draft.flag(reason)
    end

    # Already typed by hand (same day, same amount, on this account or on none: debts and loans are
    # often entered without one): shown, but not saved twice.
    def flag_existing(drafts)
      return unless @import.account_id

      taken = []
      drafts.each do |d|
        next unless d.occurred_on

        existing = @space.transactions.where(account_id: [ @import.account_id, nil ], transaction_date: d.occurred_on)
                         .where("ROUND(ABS(transactions.amount)::numeric, 2) = ?", d.amount.abs.round(2))
                         .where.not(id: taken).pick(:id)
        next unless existing

        taken << existing
        d.existing_transaction_id = existing
        d.flag("already_in_spens")
      end
    end

    def guess_account
      names = @import.reads.filter_map { _1.dig("result", "account").presence }
      return nil if names.empty?

      Classifier.new(@import).account_named(names.join(" "))
    end

    def persist(drafts)
      StatementImport.transaction do
        @import.lines.destroy_all
        records = drafts.to_h do |d|
          [ d, @import.lines.create!(**d.to_h.except(:duplicate_of, :flags), account_id: @import.account_id || d.account_id,
                                     flags: d.flags, decision: decision(d)) ]
        end
        drafts.each { |d| records[d].update!(duplicate_of: records[d.duplicate_of]) if d.duplicate_of }
        @import.update!(source: @import.reads.filter_map { _1.dig("result", "source") }.tally.max_by(&:last)&.first)
      end
    end

    # Ticked by default, except a line already in Spens, and an amount in another currency: it is
    # never saved as is, the user gives the amount in the space currency first.
    def decision(draft)
      ok = draft.proposed? && draft.existing_transaction_id.nil? && !draft.flags.include?("foreign_currency")
      ok ? "pending" : "skipped"
    end
  end
end
