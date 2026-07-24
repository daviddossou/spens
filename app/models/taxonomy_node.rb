# frozen_string_literal: true

# == Schema Information
#
# Table name: taxonomy_nodes
#
#  id         :uuid             not null, primary key
#  active     :boolean          default(TRUE), not null
#  key        :string           not null, indexed
#  kind       :string           not null, indexed => [parent_key, position]
#  name_en    :string           not null
#  name_fr    :string           not null
#  parent_key :string           indexed => [kind, position]
#  position   :integer          default(0), not null, indexed => [kind, parent_key]
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_taxonomy_nodes_on_key                               (key) UNIQUE
#  index_taxonomy_nodes_on_kind_and_parent_key_and_position  (kind,parent_key,position)
#
# One node of the category tree (parent category or subcategory). Runtime source of
# truth for TransactionTaxonomy; seeded once from config/transaction_taxonomy.yml by
# taxonomy:import_nodes, then managed from the admin dashboard.
class TaxonomyNode < ApplicationRecord
  # Catch-all keys the app relies on (default_parent_key & friends) — never deactivated.
  PROTECTED_KEYS = %w[other_expense uncategorized_expense other_income uncategorized_income].freeze

  validates :key, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_]+\z/ }
  validates :kind, inclusion: { in: TransactionTaxonomy::KINDS }
  validates :name_en, :name_fr, presence: true
  validate :key_immutable, on: :update
  validate :parent_must_be_valid

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :created_at) }
  scope :parents, -> { where(parent_key: nil) }
  scope :children_of, ->(key) { where(parent_key: key) }

  before_destroy :ensure_destroyable
  after_commit { TransactionTaxonomy.reload! }

  def parent? = parent_key.nil?

  def protected_key? = PROTECTED_KEYS.include?(key)

  def referenced? = TransactionType.where(template_key: key).exists?

  def children = self.class.children_of(key)

  private

  def key_immutable
    errors.add(:key, :immutable, message: "cannot be changed") if key_changed?
  end

  def parent_must_be_valid
    return if parent_key.blank?

    parent = self.class.parents.find_by(key: parent_key)
    if parent.nil?
      errors.add(:parent_key, "must be an existing parent category")
    elsif parent.kind != kind
      errors.add(:parent_key, "must belong to the same kind")
    end
  end

  def ensure_destroyable
    if referenced?
      errors.add(:base, "is referenced by existing categories — deactivate instead")
      throw :abort
    elsif children.exists?
      errors.add(:base, "has children — remove them first")
      throw :abort
    end
  end
end
