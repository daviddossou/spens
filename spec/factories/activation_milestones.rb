# frozen_string_literal: true

# == Schema Information
#
# Table name: activation_milestones
#
#  id         :uuid             not null, primary key
#  name       :string           not null, indexed => [user_id]
#  created_at :datetime         not null
#  user_id    :uuid             not null, indexed, indexed => [name]
#
# Indexes
#
#  index_activation_milestones_on_user_id           (user_id)
#  index_activation_milestones_on_user_id_and_name  (user_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :activation_milestone do
    user
    name { "first_account" }
  end
end
