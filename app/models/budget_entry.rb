# frozen_string_literal: true

# == Schema Information
#
# Table name: budget_entries
#
#  id                  :uuid             not null, primary key
#  kind                :string           not null
#  month               :date             not null, indexed => [space_id], indexed => [space_id, budget_item_id]
#  planned_amount      :decimal(15, 2)   not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  budget_item_id      :uuid             not null, indexed, indexed => [space_id, month]
#  space_id            :uuid             not null, indexed, indexed => [month], indexed => [budget_item_id, month]
#  transaction_type_id :uuid             indexed
#
# Indexes
#
#  index_budget_entries_on_budget_item_id       (budget_item_id)
#  index_budget_entries_on_space_id             (space_id)
#  index_budget_entries_on_space_id_and_month   (space_id,month)
#  index_budget_entries_on_space_item_month     (space_id,budget_item_id,month) UNIQUE
#  index_budget_entries_on_transaction_type_id  (transaction_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (budget_item_id => budget_items.id)
#  fk_rails_...  (space_id => spaces.id)
#  fk_rails_...  (transaction_type_id => transaction_types.id)
#
class BudgetEntry < ApplicationRecord
  ##
  # Associations
  belongs_to :space
  belongs_to :budget_item
  belongs_to :transaction_type, optional: true

  ##
  # Validations
  validates :month, presence: true
  validates :kind, presence: true, inclusion: { in: BudgetItem::KINDS }
  validates :planned_amount, presence: true, numericality: { greater_than: 0 }
  validates :budget_item_id, uniqueness: { scope: [ :space_id, :month ] }

  ##
  # Scopes
  scope :for_month, ->(month) { where(month: month.beginning_of_month) }
  scope :income, -> { where(kind: "income") }
  scope :expense, -> { where(kind: "expense") }

  def display_name
    budget_item.display_name
  end
end
