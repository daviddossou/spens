# frozen_string_literal: true

# == Schema Information
#
# Table name: learned_aliases
#
#  id             :uuid             not null, primary key
#  confirmations  :integer          default(0), not null
#  display_phrase :string
#  phrase         :string           not null, indexed => [space_id], indexed
#  source         :string           not null
#  state          :string           default("candidate"), not null, indexed
#  taxonomy_key   :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  space_id       :uuid             indexed => [phrase], indexed
#
# Indexes
#
#  index_learned_aliases_on_phrase_and_space  (phrase,space_id) UNIQUE WHERE (space_id IS NOT NULL)
#  index_learned_aliases_on_phrase_global     (phrase) UNIQUE WHERE (space_id IS NULL)
#  index_learned_aliases_on_space_id          (space_id)
#  index_learned_aliases_on_state             (state)
#
# Foreign Keys
#
#  fk_rails_...  (space_id => spaces.id)
#
class LearnedAlias < ApplicationRecord
  # A phrase -> taxonomy-key mapping that grows the rules' category vocabulary. We learn
  # transaction *types* (shared taxonomy), never accounts. Three tiers share this table:
  #   • "system" global rows — the imported built-in dictionary (ex-transaction_type_aliases.yml),
  #     served through CategoryAliasMatcher.
  #   • learned global rows — candidate-only (see Learnable), consulted by CategoryInference as a
  #     last fallback once a human approves them.
  #   • "user" personal rows (space_id set) — a space's own vocabulary, active immediately and
  #     checked FIRST, so it can override any built-in mapping.
  SOURCES = %w[edit_diff description ai miner system user].freeze
  include Learnable

  validates :taxonomy_key, presence: true

  scope :system_dictionary, -> { global.where(source: "system") }

  def self.value_attr = :taxonomy_key

  # { normalized phrase => taxonomy key } for global active aliases — loaded once per inference.
  def self.active_index
    global.active.pluck(:phrase, :taxonomy_key).to_h
  end

  # Teach (or reinforce) a global phrase -> taxonomy_key mapping (gap-fill, candidate-only).
  def self.teach(phrase:, taxonomy_key:, source:)
    candidate_teach(phrase: phrase, value: taxonomy_key, source: source, attr: :taxonomy_key)
  end

  # Teach a space's own phrase -> taxonomy_key mapping, active immediately (last correction wins).
  def self.personal_teach(space:, phrase:, taxonomy_key:)
    super(space: space, phrase: phrase, value: taxonomy_key, attr: :taxonomy_key)
  end

  # Teach a phrase -> taxonomy_key mapping as immediately active (admin corrections screen).
  def self.admin_teach(phrase:, taxonomy_key:)
    super(phrase: phrase, value: taxonomy_key, attr: :taxonomy_key)
  end

  # A phrase the built-in alias dictionary / taxonomy already resolves — or whose distinctive
  # word already lives inside a built-in phrase ("contribution" vs "contribution religieuse").
  def self.built_in?(phrase)
    return true if CategoryAliasMatcher.match(phrase).present? || TransactionTaxonomy.key_for_name(phrase).present?

    overlaps_built_in?(phrase, built_in_tokens)
  end
  private_class_method :built_in?

  def self.built_in_tokens
    @built_in_tokens ||= (CategoryAliasMatcher.phrases + taxonomy_names)
                         .flat_map { |p| significant_tokens(p) }.to_set
  end
  private_class_method :built_in_tokens

  def self.taxonomy_names
    TransactionTaxonomy.nodes.values.flat_map { |n| [ n["en"], n["fr"] ] }.compact
  end
  private_class_method :taxonomy_names
end
