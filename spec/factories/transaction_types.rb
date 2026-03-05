# == Schema Information
#
# Table name: transaction_types
#
#  id          :uuid             not null, primary key
#  budget_goal :float            default(0.0)
#  kind        :string           not null, indexed
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  space_id    :uuid             not null, indexed
#
# Indexes
#
#  index_transaction_types_on_kind                       (kind)
#  index_transaction_types_on_lower_name_space_and_kind  (lower((name)::text), space_id, kind) UNIQUE
#  index_transaction_types_on_space_id                   (space_id)
#
# Foreign Keys
#
#  fk_rails_...  (space_id => spaces.id)
#
FactoryBot.define do
  factory :transaction_type do
    transient do
      user { nil }
    end

    sequence(:name) { |n| "Category #{n}" }
    kind { :expense }
    budget_goal { 0.0 }

    space do
      if user
        user.spaces.first || association(:space, user: user)
      else
        association(:space)
      end
    end
  end
end
