FactoryBot.define do
  factory :transaction do
    association :user
    association :account
    association :transaction_type
    sequence(:description) { |n| "Transaction #{n}" }
    amount { 12.34 }
    transaction_date { Date.today }
    note { "Optional note" }
  end
end
