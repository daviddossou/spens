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
class PushSubscription < ApplicationRecord
  belongs_to :user

  validates :endpoint, presence: true, uniqueness: true
  validates :p256dh, :auth, presence: true

  # A browser hands the same endpoint back on every visit: move it to whoever is signed in.
  def self.register(user:, endpoint:, p256dh:, auth:, user_agent: nil)
    subscription = find_or_initialize_by(endpoint: endpoint)
    subscription.update!(user: user, p256dh: p256dh, auth: auth, user_agent: user_agent.to_s.first(255))
    subscription
  end
end
