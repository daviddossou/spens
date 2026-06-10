# frozen_string_literal: true

# == Schema Information
#
# Table name: quick_entry_attempts
#
#  id             :uuid             not null, primary key
#  ai_draft       :jsonb
#  ai_used        :boolean          default(FALSE), not null
#  locale         :string
#  outcome        :string           default("pending"), not null, indexed
#  rules_draft    :jsonb            not null
#  source         :string           not null
#  text           :text             not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  space_id       :uuid             not null, indexed
#  transaction_id :uuid             indexed
#  user_id        :uuid             not null, indexed
#
# Indexes
#
#  index_quick_entry_attempts_on_outcome         (outcome)
#  index_quick_entry_attempts_on_space_id        (space_id)
#  index_quick_entry_attempts_on_transaction_id  (transaction_id)
#  index_quick_entry_attempts_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (space_id => spaces.id)
#  fk_rails_...  (transaction_id => transactions.id) ON DELETE => nullify
#  fk_rails_...  (user_id => users.id)
#
# One quick-add submission: the raw utterance, what the rules (and later the AI) parsed, and
# the transaction it produced. The memory the learning loop is built on — edits diff against
# `rules_draft`, and the miner reads these in bulk to grow the alias dictionary.
class QuickEntryAttempt < ApplicationRecord
  ##
  # Associations
  belongs_to :space
  belongs_to :user
  # Named to avoid shadowing ActiveRecord's #transaction; the column is transaction_id.
  belongs_to :created_transaction, class_name: "Transaction", foreign_key: :transaction_id, optional: true

  SOURCES = %w[rules ai manual_fallback].freeze

  enum :outcome, {
    pending: "pending",  # just created, not yet acted on
    kept: "kept",        # left unchanged → its parse was right
    edited: "edited",    # corrected → a learning signal
    deleted: "deleted"   # thrown away → its parse was wrong
  }

  ##
  # Validations
  validates :text, presence: true
  validates :source, inclusion: { in: SOURCES }

  # Records one submission. `draft` is the parsed Draft we acted on; `transaction` is the
  # auto-created record (nil when we fell back to the manual form).
  def self.record(space:, user:, text:, locale:, draft:, transaction: nil)
    create!(
      space: space,
      user: user,
      text: text.to_s,
      locale: locale.to_s,
      rules_draft: draft.to_h,
      source: transaction ? "rules" : "manual_fallback",
      transaction_id: transaction&.id
    )
  end
end
