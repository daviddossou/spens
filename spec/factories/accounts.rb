# == Schema Information
#
# Table name: accounts
#
#  id          :uuid             not null, primary key
#  balance     :float            default(0.0), not null
#  name        :string           not null
#  saving_goal :float            default(0.0)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  space_id    :uuid             not null, indexed
#  user_id     :uuid             indexed
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
    end

    sequence(:name) { |n| "Account #{n}" }
    balance { 0.0 }
    saving_goal { 0.0 }

    space do
      if user
        user.spaces.first || association(:space, user: user)
      else
        association(:space)
      end
    end
  end
end
