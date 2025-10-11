FactoryBot.define do
  factory :account do
    association :user
    sequence(:name) { |n| "Account #{n}" }
    balance { 0.0 }
    saving_goal { 0.0 }
  end
end
