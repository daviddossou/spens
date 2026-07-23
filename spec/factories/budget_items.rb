# == Schema Information
#
# Table name: budget_items
#
#  id                  :uuid             not null, primary key
#  active              :boolean          default(TRUE), not null
#  amount              :decimal(15, 2)   not null
#  ends_on             :date
#  frequency           :string           not null
#  kind                :string           not null, indexed => [space_id, debt_id]
#  starts_on           :date             not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  debt_id             :uuid             indexed, indexed => [space_id, kind]
#  from_account_id     :uuid             indexed, indexed => [space_id, to_account_id]
#  space_id            :uuid             not null, indexed => [debt_id, kind], indexed => [from_account_id, to_account_id], indexed => [transaction_type_id], indexed
#  to_account_id       :uuid             indexed => [space_id, from_account_id], indexed
#  transaction_type_id :uuid             indexed => [space_id], indexed
#
# Indexes
#
#  index_budget_items_on_debt_id                    (debt_id)
#  index_budget_items_on_from_account_id            (from_account_id)
#  index_budget_items_on_space_and_debt_active      (space_id,debt_id,kind) UNIQUE WHERE (active AND (debt_id IS NOT NULL))
#  index_budget_items_on_space_and_transfer_active  (space_id,from_account_id,to_account_id) UNIQUE WHERE (active AND (from_account_id IS NOT NULL))
#  index_budget_items_on_space_and_type_active      (space_id,transaction_type_id) UNIQUE WHERE (active AND (transaction_type_id IS NOT NULL))
#  index_budget_items_on_space_id                   (space_id)
#  index_budget_items_on_to_account_id              (to_account_id)
#  index_budget_items_on_transaction_type_id        (transaction_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (debt_id => debts.id)
#  fk_rails_...  (from_account_id => accounts.id)
#  fk_rails_...  (space_id => spaces.id)
#  fk_rails_...  (to_account_id => accounts.id)
#  fk_rails_...  (transaction_type_id => transaction_types.id)
#
FactoryBot.define do
  factory :budget_item do
    space
    transaction_type { association(:transaction_type, space: space, kind: kind) }
    kind { "expense" }
    amount { 25_000 }
    frequency { "monthly" }
    starts_on { Date.current.beginning_of_month }
    active { true }

    trait :transfer do
      kind { "transfer" }
      transaction_type { nil }
      from_account { association(:account, space: space) }
      to_account { association(:account, space: space) }
    end

    trait :debt do
      kind { "debt_in" }
      transaction_type { nil }
      debt { association(:debt, space: space) }
    end
  end
end
