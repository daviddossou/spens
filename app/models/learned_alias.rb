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
# A learned phrase -> taxonomy-key mapping that grows the rules' vocabulary from real usage.
# Global on purpose: we learn transaction *types* (shared taxonomy), never accounts. Consulted
# by CategoryInference as a last fallback, so it only ever *fills gaps* the built-in YAML /
# taxonomy don't already cover — it can never shadow a built-in mapping.
class LearnedAlias < ApplicationRecord
  SOURCES = %w[edit_diff ai miner].freeze

  enum :state, {
    candidate: "candidate",  # seen once from an unverified source (AI) — not yet trusted
    active: "active",        # trusted: consulted by the rules
    rejected: "rejected"     # known-bad, kept so we don't relearn it
  }

  validates :phrase, presence: true, uniqueness: true
  validates :taxonomy_key, presence: true
  validates :source, inclusion: { in: SOURCES }

  # { normalized phrase => taxonomy key } for active aliases — loaded once per inference.
  def self.active_index
    active.pluck(:phrase, :taxonomy_key).to_h
  end

  # Teach (or reinforce) a phrase -> taxonomy_key mapping. Gap-fill only (never shadows a
  # built-in). A human edit (edit_diff) is trusted and activates at once; an AI guess starts as
  # a candidate. Repeated agreement promotes to active; a conflicting unverified guess is held.
  def self.teach(phrase:, taxonomy_key:, source:)
    return if CategoryText.normalize(phrase).length < 2
    return if built_in?(phrase)

    row = find_or_initialize_by(phrase: CategoryText.normalize(phrase))
    apply_teaching(row, taxonomy_key, source)
    row.save!
    row
  end

  def self.built_in?(phrase)
    CategoryAliasMatcher.match(phrase).present? || TransactionTaxonomy.key_for_name(phrase).present?
  end

  def self.apply_teaching(row, taxonomy_key, source)
    if row.new_record?
      row.assign_attributes(taxonomy_key: taxonomy_key, source: source,
                            state: trusted?(source) ? "active" : "candidate", confirmations: 1)
    elsif row.taxonomy_key == taxonomy_key
      row.confirmations += 1
      row.state = "active"
    elsif trusted?(source)
      row.assign_attributes(taxonomy_key: taxonomy_key, source: source, state: "active", confirmations: 1)
    else
      row.state = "candidate"
    end
  end

  def self.trusted?(source)
    source == "edit_diff"
  end

  private_class_method :built_in?, :apply_teaching, :trusted?
end
