# frozen_string_literal: true

module QuickEntry
  # The offline miner the rest of the learning loop refers to: it turns the *kind* corrections
  # CorrectionLearner only records (QuickEntryAttempt#corrections) into candidate vocabulary.
  #
  # CorrectionLearner already teaches the category correction live (an edit_diff LearnedAlias), but
  # leaves the kind change as a recorded signal — the verb a user revealed by re-typing a plain
  # expense as a transfer or a debt. The miner reads those signals and teaches a LearnedKeyword
  # candidate (source: "miner"), so the rules can classify the same phrase next time, AI-free.
  #
  # Gap-fill + candidate-only (via LearnedKeyword.teach): nothing it produces is consulted by the
  # rules until a human approves it in the admin dashboard. Each attempt is stamped #mined_at so
  # reruns are incremental and a phrase is never counted twice for the same correction.
  class Miner
    Candidate = Struct.new(:phrase, :kind, :text, keyword_init: true)
    Result = Struct.new(:scanned, :candidates, keyword_init: true)

    def self.run(...) = new(...).run

    def initialize(dry_run: false, scope: nil)
      @dry_run = dry_run
      @scope = scope || QuickEntryAttempt.edited.where(mined_at: nil)
    end

    def run
      candidates = []
      scanned = 0

      @scope.find_each do |attempt|
        scanned += 1
        candidate = mine(attempt)
        candidates << candidate if candidate
        attempt.update_columns(mined_at: Time.current) unless @dry_run
      end

      Result.new(scanned: scanned, candidates: candidates)
    end

    private

    # A single attempt's kind correction -> a candidate keyword, or nil when there's nothing
    # structural to learn (no kind change, an expense/income correction, or no residual phrase).
    def mine(attempt)
      change = attempt.corrections&.dig("kind") or return nil
      kind = structural_kind(change["to"]) or return nil
      phrase = PhraseExtractor.call(
        text: attempt.text, locale: attempt.locale, space: attempt.space,
        exclude: exclude_names(attempt)
      ) or return nil

      unless @dry_run
        LearnedKeyword.teach(phrase: phrase, kind: kind, source: "miner") or return nil
      end

      Candidate.new(phrase: phrase, kind: kind, text: attempt.text)
    end

    # Only the structural kinds are learnable as keywords; expense/income ride on their category
    # (taught as aliases), so a correction into one of those is not a keyword signal.
    def structural_kind(kind)
      k = kind.to_s
      return "transfer" if k.start_with?("transfer")

      k if LearnedKeyword::KINDS.include?(k)
    end

    # Drop the resolved person from the residual phrase ("il m'a dépanné Ali" -> "depanne", not
    # "ali"). Accounts are already excluded by PhraseExtractor.
    def exclude_names(attempt)
      [ attempt.created_transaction&.debt&.name ].compact
    end
  end
end
