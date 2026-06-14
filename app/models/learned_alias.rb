# frozen_string_literal: true

# == Schema Information
#
# Table name: learned_aliases
#
#  id            :uuid             not null, primary key
#  confirmations :integer          default(0), not null
#  phrase        :string           not null, indexed
#  source        :string           not null
#  state         :string           default("candidate"), not null, indexed
#  taxonomy_key  :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_learned_aliases_on_phrase  (phrase) UNIQUE
#  index_learned_aliases_on_state   (state)
#
class LearnedAlias < ApplicationRecord
  # A learned phrase -> taxonomy-key mapping that grows the rules' category vocabulary from real
  # usage. Global on purpose: we learn transaction *types* (shared taxonomy), never accounts.
  # Consulted by CategoryInference as a last fallback, so it only ever *fills gaps* the built-in
  # YAML / taxonomy don't already cover — it can never shadow a built-in mapping. Candidate-only:
  # see Learnable (a human approval in the dashboard is what makes a candidate `active`).
  SOURCES = %w[edit_diff ai miner].freeze
  include Learnable

  validates :taxonomy_key, presence: true

  # { normalized phrase => taxonomy key } for active aliases — loaded once per inference.
  def self.active_index
    active.pluck(:phrase, :taxonomy_key).to_h
  end

  # Teach (or reinforce) a phrase -> taxonomy_key mapping (gap-fill, candidate-only).
  def self.teach(phrase:, taxonomy_key:, source:)
    candidate_teach(phrase: phrase, value: taxonomy_key, source: source, attr: :taxonomy_key)
  end

  # A phrase the built-in alias dictionary / taxonomy already resolves — nothing to learn.
  def self.built_in?(phrase)
    CategoryAliasMatcher.match(phrase).present? || TransactionTaxonomy.key_for_name(phrase).present?
  end
  private_class_method :built_in?
end
