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
FactoryBot.define do
  factory :budget_entry do
    space
    budget_item { association(:budget_item, space: space, kind: kind) }
    transaction_type { budget_item&.transaction_type }
    month { Date.current.beginning_of_month }
    kind { "expense" }
    planned_amount { 25_000 }
  end
end
