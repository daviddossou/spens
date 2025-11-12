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
#  user_id     :uuid             not null, indexed
#
# Indexes
#
#  index_transaction_types_on_kind                      (kind)
#  index_transaction_types_on_lower_name_user_and_kind  (lower((name)::text), user_id, kind) UNIQUE
#  index_transaction_types_on_user_id                   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :transaction_type do
    association :user
    sequence(:name) { |n| "Category #{n}" }
    kind { :expense }
    budget_goal { 0.0 }
  end
end
