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
#  user_id     :uuid             not null, indexed
#
# Indexes
#
#  index_accounts_on_lower_name_and_user_id  (lower((name)::text), user_id) UNIQUE
#  index_accounts_on_user_id                 (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :account do
    association :user
    sequence(:name) { |n| "Account #{n}" }
    balance { 0.0 }
    saving_goal { 0.0 }
  end
end
