# frozen_string_literal: true

# Shared behaviour for the learned-vocabulary models (LearnedAlias, LearnedKeyword): one
# global mapping from a normalized phrase to a learned value, grown from real usage.
#
# Candidate-only on purpose. Everything a learner produces — even a human's own edit-diff —
# starts as a `candidate` and is consulted by the rules ONLY after a human approves it (the
# review dashboard). Nothing auto-activates; recurrence merely strengthens a candidate
# (confirmations + source), so the reviewer (and a future grace-period promoter) can rank it.
#
# Including model must define: SOURCES (allowed sources), a `value_attr` (the column holding
# the learned value), and a `built_in?(phrase)` class method (so we only ever fill gaps the
# built-ins don't already cover).
module Learnable
  extend ActiveSupport::Concern

  # Lower rank = more trustworthy. On agreement we keep the strongest source seen, so a
  # candidate an actual user-edit confirmed outranks a pure AI guess in the dashboard.
  SOURCE_RANK = { "edit_diff" => 0, "miner" => 1, "ai" => 2 }.freeze

  included do
    enum :state, {
      candidate: "candidate", # learned but unverified — NOT yet consulted by the rules
      active: "active",       # human-approved — the rules now use it
      rejected: "rejected"    # known-bad — kept so we don't relearn it
    }

    validates :phrase, presence: true, uniqueness: true
    validates :source, inclusion: { in: self::SOURCES }
  end

  def approve! = update!(state: "active")
  def reject!  = update!(state: "rejected")

  class_methods do
    # Teach (or reinforce) a phrase -> value mapping. Gap-fill only (never shadows a built-in)
    # and candidate-only (only a human approval reaches `active`).
    def candidate_teach(phrase:, value:, source:, attr:)
      return if CategoryText.normalize(phrase).length < 2
      return if built_in?(phrase)

      row = find_or_initialize_by(phrase: CategoryText.normalize(phrase))
      apply_teaching(row, attr, value, source)
      row.save!
      row
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
  end
end
