# frozen_string_literal: true

# == Schema Information
#
# Table name: category_memories
#
#  id            :uuid             not null, primary key
#  confirmations :integer          default(1), not null
#  taxonomy_key  :string           not null
#  tokens        :string           default([]), not null, is an Array, indexed => [space_id]
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  space_id      :uuid             not null, indexed, indexed => [tokens]
#
# Indexes
#
#  index_category_memories_on_space_id             (space_id)
#  index_category_memories_on_space_id_and_tokens  (space_id,tokens) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (space_id => spaces.id)
#
class CategoryMemory < ApplicationRecord
  MAX_TOKENS = 8

  belongs_to :space

  validates :taxonomy_key, presence: true
  validates :tokens, presence: true

  # Store (or reinforce) one memory. Same set + same category strengthens the memory;
  # same set + different category replaces it (the user's last word wins).
  def self.remember(space:, tokens:, taxonomy_key:)
    set = Array(tokens).map { |t| CategoryText.normalize(t) }
                       .reject(&:blank?).uniq.sort.first(MAX_TOKENS)
    return nil if set.empty?

    row = find_or_initialize_by(space: space, tokens: set)
    if row.persisted? && row.taxonomy_key == taxonomy_key
      row.increment!(:confirmations)
    else
      row.update!(taxonomy_key: taxonomy_key, confirmations: 1)
    end
    row
  end
end
