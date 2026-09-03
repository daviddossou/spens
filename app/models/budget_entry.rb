# frozen_string_literal: true

# == Schema Information
#
# Table name: budget_entries
#
#  id                  :uuid             not null, primary key
#  carried_amount      :decimal(15, 2)   default(0.0), not null
#  kind                :string           not null
#  month               :date             not null, indexed => [space_id], indexed => [space_id, budget_item_id]
#  overridden          :boolean          default(FALSE), not null
#  overridden_at       :datetime
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
  # Callbacks
  # Meta activation milestone: the month's budget counts as filled once it plans
  # both income and expenses (CAPI-only, once per user) — the guide's end goal.
  after_create_commit :record_meta_budget_complete

  ##
  # Scopes
  scope :for_month, ->(month) { where(month: month.beginning_of_month) }
  scope :income, -> { where(kind: "income") }
  scope :expense, -> { where(kind: "expense") }

  def display_name
    budget_item.display_name
  end

  # What the recurring rule would plan for this month, ignoring any hand-set
  # exception — used for "usually 120K" and the revert target.
  def rule_amount
    budget_item.planned_amount_for(month)
  end

  # Set (or clear) a per-month exception. Marking it stamps when it was posted;
  # an amount equal to the rule isn't an exception at all.
  def override_to(amount)
    diverges = amount.to_f != rule_amount.to_f
    update(
      planned_amount: amount,
      overridden: diverges,
      overridden_at: diverges ? (overridden? ? overridden_at : Time.current) : nil
    )
  end

  # Drop the exception: the month goes back to whatever the rule plans.
  def revert_to_rule!
    update!(planned_amount: rule_amount, overridden: false, overridden_at: nil)
  end

  private

  def record_meta_budget_complete
    scope = space.budget_entries.for_month(month)
    return unless scope.income.exists? && scope.expense.exists?

    Meta::Activation.record(space.user, :spens_budget_complete)
  end
end
