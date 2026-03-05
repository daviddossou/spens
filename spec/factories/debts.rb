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
#  space_id         :uuid             not null, indexed
#
# Indexes
#
#  index_debts_on_space_id  (space_id)
#  index_debts_on_status    (status)
#
# Foreign Keys
#
#  fk_rails_...  (space_id => spaces.id)
#
FactoryBot.define do
  factory :debt do
    transient do
      user { nil }
    end

    sequence(:name) { |n| "Contact #{n}" }
    note { "Test note" }
    status { "ongoing" }
    direction { "lent" }
    total_lent { 1000.0 }
    total_reimbursed { 0.0 }

    space do
      if user
        user.spaces.first || association(:space, user: user)
      else
        association(:space)
      end
    end

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
