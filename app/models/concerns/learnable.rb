# frozen_string_literal: true

# Shared behaviour for the learned-vocabulary models (LearnedAlias, LearnedKeyword): mappings
# from a normalized phrase to a learned value, grown from real usage. Two tiers live in the
# same table:
#
#   • GLOBAL rows (space_id nil) — the shared vocabulary. "system" rows are the imported
#     built-in dictionary; everything a learner produces starts as a `candidate` and is
#     consulted by the rules ONLY after a human approves it (the review dashboard).
#   • PERSONAL rows (space_id set) — one space's own vocabulary, ACTIVE immediately: the user's
#     correction IS the approval. Last correction wins. Personal rows outrank every global
#     mapping at inference time, so a space can override a built-in ("carrefour" -> their pick).
#
# Including model must define: SOURCES (allowed sources), a `value_attr` (the column holding
# the learned value), and a `built_in?(phrase)` class method (so global candidates only ever
# fill gaps the built-ins don't already cover — personal teaching skips that gate on purpose).
module Learnable
  extend ActiveSupport::Concern

  # Lower rank = more trustworthy. On agreement we keep the strongest source seen, so a
  # candidate an actual user-edit confirmed outranks a pure AI guess in the dashboard.
  SOURCE_RANK = { "edit_diff" => 0, "description" => 1, "miner" => 2, "ai" => 3 }.freeze

  included do
    belongs_to :space, optional: true

    enum :state, {
      candidate: "candidate", # learned but unverified — NOT yet consulted by the rules
      active: "active",       # human-approved — the rules now use it
      rejected: "rejected"    # known-bad — kept so we don't relearn it
    }

    validates :phrase, presence: true, uniqueness: { scope: :space_id }
    validates :source, inclusion: { in: self::SOURCES }

    scope :global, -> { where(space_id: nil) }
    scope :personal, -> { where.not(space_id: nil) }
    scope :for_space, ->(space) { where(space: space) }
  end

  def approve! = update!(state: "active")
  def reject!  = update!(state: "rejected")

  def display_or_phrase = display_phrase.presence || phrase

  class_methods do
    # Teach (or reinforce) a GLOBAL phrase -> value mapping. Gap-fill only (never shadows a
    # built-in) and candidate-only (only a human approval reaches `active`).
    def candidate_teach(phrase:, value:, source:, attr:)
      return if CategoryText.normalize(phrase).length < 2
      return if built_in?(phrase)

      row = find_or_initialize_by(phrase: CategoryText.normalize(phrase), space_id: nil)
      row.display_phrase ||= phrase.to_s.strip
      apply_teaching(row, attr, value, source)
      row.save!
      row
    end

    # Teach a PERSONAL (space-scoped) phrase -> value mapping, active immediately: the user's
    # own correction needs no review. Last correction wins — a re-correction simply replaces
    # the value, so a bad mapping self-repairs on the next edit. No built-in gate: overriding
    # the default vocabulary is the whole point.
    def personal_teach(space:, phrase:, value:, attr:)
      normalized = CategoryText.normalize(phrase)
      return nil if normalized.length < 2

      row = find_or_initialize_by(phrase: normalized, space: space)
      previous = row.persisted? ? row.public_send(attr) : nil
      row.assign_attributes(attr => value, state: "active", source: "user",
                            display_phrase: phrase.to_s.strip)
      row.confirmations = previous == value ? row.confirmations + 1 : 1
      row.save!
      row
    end

    # { normalized phrase => value } of a space's own active vocabulary — checked before every
    # global mapping at inference time.
    def personal_index(space)
      return {} if space.nil?

      for_space(space).active.pluck(:phrase, value_attr).to_h
    end

    private

    def apply_teaching(row, attr, value, source)
      if row.new_record?
        row.assign_attributes(attr => value, source: source, state: "candidate", confirmations: 1)
      elsif row.public_send(attr) == value
        row.confirmations += 1                          # agreement strengthens it...
        row.source = stronger_source(row.source, source) # ...and records the better evidence
      elsif row.candidate?
        # a still-pending guess, now contradicted: replace it, reset the count, stay a candidate
        row.assign_attributes(attr => value, source: source, confirmations: 1)
      end
      # active (human-approved) or rejected: a human decided — an unverified relearn can't disturb it
    end

    def stronger_source(current, incoming)
      SOURCE_RANK.fetch(incoming, 99) < SOURCE_RANK.fetch(current, 99) ? incoming : current
    end

    public

    # Direct human teaching (admin corrections screen): the reviewer IS the approval, so the
    # row is written active immediately — unlike candidate_teach, which waits for the queue.
    def admin_teach(phrase:, value:, attr:, source: "edit_diff")
      normalized = CategoryText.normalize(phrase)
      return nil if normalized.length < 2

      row = find_or_initialize_by(phrase: normalized, space_id: nil)
      row.display_phrase ||= phrase.to_s.strip
      row.assign_attributes(attr => value, state: "active", source: row.source.presence || source)
      row.confirmations = [ row.confirmations.to_i, 1 ].max
      row.save!
      row
    end

    private

    # Token-level containment against the built-in vocabulary: a candidate whose distinctive
    # word (>= 4 chars) already appears inside a built-in phrase ("contribution" vs
    # "contribution religieuse") teaches nothing new.
    def overlaps_built_in?(phrase, built_in_tokens)
      significant_tokens(phrase).any? { |t| built_in_tokens.include?(t) }
    end

    def significant_tokens(phrase)
      I18n.transliterate(phrase.to_s).downcase.split(/[^a-z0-9]+/).select { |t| t.length >= 4 }
    end
  end
end
