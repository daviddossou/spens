# == Schema Information
#
# Table name: accounts
#
#  id                    :uuid             not null, primary key
#  balance               :float            default(0.0), not null
#  name                  :string           not null
#  savings_goal          :boolean          default(FALSE), not null
#  savings_goal_amount   :float
#  savings_goal_deadline :date
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  space_id              :uuid             not null, indexed
#  user_id               :uuid             indexed
#
# Indexes
#
#  index_accounts_on_lower_name_and_space_id  (lower((name)::text), space_id) UNIQUE
#  index_accounts_on_space_id                 (space_id)
#  index_accounts_on_user_id                  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (space_id => spaces.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :account do
    transient do
      user { nil }
      # Back-compat shorthand: `saving_goal: 5000` sets the amount and flags the
      # account as a savings goal.
      saving_goal { nil }
    end

    sequence(:name) { |n| "Account #{n}" }
    balance { 0.0 }
    savings_goal_amount { saving_goal }
    savings_goal { saving_goal.to_f.positive? }

    trait :savings do
      savings_goal { true }
    end

    space do
      if user
        user.spaces.first || association(:space, user: user)
      else
        association(:space)
      end
    end
  end
end
