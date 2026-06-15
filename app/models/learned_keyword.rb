# frozen_string_literal: true

# == Schema Information
#
# Table name: learned_keywords
#
#  id            :uuid             not null, primary key
#  confirmations :integer          default(0), not null
#  kind          :string           not null
#  phrase        :string           not null, indexed
#  source        :string           not null
#  state         :string           default("candidate"), not null, indexed
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_learned_keywords_on_phrase  (phrase) UNIQUE
#  index_learned_keywords_on_state   (state)
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
  SOURCES = %w[edit_diff ai miner].freeze
  KINDS = %w[transfer debt_in debt_out].freeze
  include Learnable

  validates :kind, inclusion: { in: KINDS }

  # { normalized phrase => kind } for active keywords — consulted by Parser#detect_kind.
  def self.active_index
    active.pluck(:phrase, :kind).to_h
  end

  # Teach (or reinforce) a phrase -> kind mapping (gap-fill, candidate-only).
  def self.teach(phrase:, kind:, source:)
    candidate_teach(phrase: phrase, value: kind, source: source, attr: :kind)
  end

  # A phrase the built-in kind keywords (either language) already classify — nothing to learn.
  def self.built_in?(phrase)
    normalized = CategoryText.normalize(phrase)
    %w[en fr].any? do |lang|
      QuickEntry::Keywords.kind(lang).values.flatten.any? do |keyword|
        normalized.include?(CategoryText.normalize(keyword))
      end
    end
  end
  private_class_method :built_in?
end
