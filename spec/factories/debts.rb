# == Schema Information
#
# Table name: debts
#
#  id               :uuid             not null, primary key
#  direction        :string           default("lent"), not null
#  name             :string           not null
#  note             :text
#  status           :string           default("ongoing"), not null, indexed
#  total_lent       :float            default(0.0), not null
#  total_reimbursed :float            default(0.0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :uuid             not null, indexed
#
# Indexes
#
#  index_debts_on_status   (status)
#  index_debts_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :debt do
    association :user
    sequence(:name) { |n| "Contact #{n}" }
    note { "Test note" }
    status { "ongoing" }
    direction { "lent" }
    total_lent { 1000.0 }
    total_reimbursed { 0.0 }

    trait :borrowed do
      direction { "borrowed" }
    end

    trait :paid do
      status { "paid" }
      total_reimbursed { total_lent }
    end

    trait :partially_reimbursed do
      total_reimbursed { total_lent / 2 }
    end
  end
end
