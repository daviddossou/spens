# frozen_string_literal: true

# == Schema Information
#
# Table name: learned_keywords
#
#  id             :uuid             not null, primary key
#  confirmations  :integer          default(0), not null
#  display_phrase :string
#  kind           :string           not null
#  phrase         :string           not null, indexed => [space_id], indexed
#  source         :string           not null
#  state          :string           default("candidate"), not null, indexed
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  space_id       :uuid             indexed => [phrase], indexed
#
# Indexes
#
#  index_learned_keywords_on_phrase_and_space  (phrase,space_id) UNIQUE WHERE (space_id IS NOT NULL)
#  index_learned_keywords_on_phrase_global     (phrase) UNIQUE WHERE (space_id IS NULL)
#  index_learned_keywords_on_space_id          (space_id)
#  index_learned_keywords_on_state             (state)
#
# Foreign Keys
#
#  fk_rails_...  (space_id => spaces.id)
#
class LearnedKeyword < ApplicationRecord
  # A learned phrase -> *kind* mapping — the sibling of LearnedAlias for kind detection. It grows
  # the rules' structural vocabulary (the verbs that signal a transfer or a debt) from real usage:
  # e.g. when the AI rescues "j'ai dépanné Ali" the rules read as an expense, we capture
  # "depanne -> debt_out" so the rules can classify it next time, AI-free.
  #
  # Only the STRUCTURAL kinds need this. expense/income ride on their category: once a category
  # alias is learned, Parser#resolve_category settles the kind from it — so there's no expense or
  # income keyword to learn here. Candidate-only (see Learnable): a human approval activates it.
  SOURCES = %w[edit_diff ai miner user].freeze
  KINDS = %w[transfer debt_in debt_out].freeze
  include Learnable

  validates :kind, inclusion: { in: KINDS }

  def self.value_attr = :kind

  # { normalized phrase => kind } for global active keywords — consulted by Parser#detect_kind.
  def self.active_index
    global.active.pluck(:phrase, :kind).to_h
  end

  # Teach (or reinforce) a global phrase -> kind mapping (gap-fill, candidate-only).
  def self.teach(phrase:, kind:, source:)
    candidate_teach(phrase: phrase, value: kind, source: source, attr: :kind)
  end

  # Teach a space's own phrase -> kind mapping, active immediately (last correction wins).
  def self.personal_teach(space:, phrase:, kind:)
    super(space: space, phrase: phrase, value: kind, attr: :kind)
  end

  # Teach a phrase -> kind mapping as immediately active (admin corrections screen).
  def self.admin_teach(phrase:, kind:)
    super(phrase: phrase, value: kind, attr: :kind)
  end

  # A phrase the built-in kind keywords (either language) already classify — nothing to learn.
  def self.built_in?(phrase)
    normalized = CategoryText.normalize(phrase)
    return true if %w[en fr].any? do |lang|
      QuickEntry::Keywords.kind(lang).values.flatten.any? do |keyword|
        normalized.include?(CategoryText.normalize(keyword))
      end
    end

    overlaps_built_in?(phrase, built_in_tokens)
  end
  private_class_method :built_in?

  def self.built_in_tokens
    @built_in_tokens ||= %w[en fr].flat_map { |lang| QuickEntry::Keywords.kind(lang).values.flatten }
                                  .flat_map { |p| significant_tokens(p) }.to_set
  end
  private_class_method :built_in_tokens
end
