# == Schema Information
#
# Table name: push_subscriptions
#
#  id           :uuid             not null, primary key
#  auth         :string           not null
#  endpoint     :text             not null, indexed
#  last_used_at :datetime
#  p256dh       :string           not null
#  user_agent   :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :uuid             not null, indexed
#
# Indexes
#
#  index_push_subscriptions_on_endpoint  (endpoint) UNIQUE
#  index_push_subscriptions_on_user_id   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :push_subscription do
    user
    sequence(:endpoint) { |n| "https://push.example.com/send/#{n}" }
    p256dh { "BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8QcYP7DkM" }
    auth { "tBHItJI5svbpez7KI4CCXg" }
  end
end
