# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           default(""), not null, indexed
#  encrypted_password     :string           default(""), not null
#  first_name             :string
#  last_name              :string
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  otp_code               :string
#  otp_sent_at            :datetime
#  phone_number           :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string           indexed
#  sign_in_count          :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    first_name { "John" }
    last_name { "Doe" }
    phone_number { "+1234567890" }

    # Transient attributes that map to the auto-created default space.
    # This provides backward compatibility with existing specs that passed
    # onboarding_current_step, currency, country, etc. to the user factory.
    transient do
      onboarding_current_step { "onboarding_completed" }
      currency { "XOF" }
      country { "BJ" }
      income_frequency { nil }
      main_income_source { nil }
      financial_goals { [] }
      create_default_space { true }
    end

    after(:create) do |user, evaluator|
      next unless evaluator.create_default_space

      create(:space,
        user: user,
        name: "Personal",
        currency: evaluator.currency,
        country: evaluator.country,
        onboarding_current_step: evaluator.onboarding_current_step,
        income_frequency: evaluator.income_frequency,
        main_income_source: evaluator.main_income_source,
        financial_goals: evaluator.financial_goals
      )
    end

    trait :onboarding_incomplete do
      onboarding_current_step { "onboarding_financial_goal" }
    end

    trait :without_space do
      create_default_space { false }
    end
  end
end
