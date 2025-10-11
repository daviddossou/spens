FactoryBot.define do
  factory :transaction_type do
    association :user
    sequence(:name) { |n| "Category #{n}" }
    kind { :expense }
    budget_goal { 0.0 }
  end
end
