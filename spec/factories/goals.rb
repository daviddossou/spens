# == Schema Information
#
# Table name: goals
#
#  id            :uuid             not null, primary key
#  deadline      :date
#  name          :string           not null
#  target_amount :decimal(15, 2)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :uuid             not null, indexed
#  space_id      :uuid             not null, indexed
#
# Indexes
#
#  index_goals_on_account_id  (account_id) UNIQUE
#  index_goals_on_space_id    (space_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (space_id => spaces.id)
#
FactoryBot.define do
  factory :goal do
    sequence(:name) { |n| "Goal #{n}" }
    target_amount { nil }
    deadline { nil }
    space
    account { association(:account, space: space) }
  end
end
