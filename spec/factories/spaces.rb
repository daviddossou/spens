# == Schema Information
#
# Table name: spaces
#
#  id                      :uuid             not null, primary key
#  country                 :string
#  currency                :string           default("XOF")
#  financial_goals         :jsonb
#  income_frequency        :string
#  main_income_source      :string
#  name                    :string           not null
#  onboarding_current_step :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  user_id                 :uuid             not null, indexed
#
# Indexes
#
#  index_spaces_on_user_id                 (user_id)
#  index_spaces_on_user_id_and_lower_name  (user_id, lower((name)::text)) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :space do
    association :user
    sequence(:name) { |n| "Space #{n}" }
    currency { "XOF" }
    country { "BJ" }
    onboarding_current_step { "onboarding_completed" }

    trait :onboarding_incomplete do
      onboarding_current_step { "onboarding_financial_goal" }
    end

    trait :onboarding_profile_setup do
      onboarding_current_step { "onboarding_profile_setup" }
    end

    trait :onboarding_account_setup do
      onboarding_current_step { "onboarding_account_setup" }
    end
  end
end
