# frozen_string_literal: true

# Sends one notification to every browser a user subscribed from. A subscription the push
# service no longer knows is deleted. Returns how many browsers were reached.
class Reminders::WebPushDelivery
  def self.configured?
    Rails.application.config.x.web_push.present?
  end

  def initialize(user)
    @user = user
  end

  def call(title:, body:, url:)
    return 0 unless self.class.configured?

    payload = { title: title, body: body, url: url }.to_json
    @user.push_subscriptions.count { |subscription| deliver(subscription, payload) }
  end

  private

  def deliver(subscription, payload)
    WebPush.payload_send(message: payload, endpoint: subscription.endpoint, p256dh: subscription.p256dh,
                         auth: subscription.auth, vapid: Rails.application.config.x.web_push, ttl: 4.hours.to_i)
    subscription.update_column(:last_used_at, Time.current)
    true
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
    subscription.destroy
    false
  rescue WebPush::ResponseError, SocketError, Timeout::Error, OpenSSL::SSL::SSLError => e
    Rails.logger.warn("[Reminders] push failed: #{e.class} #{e.message}")
    false
  end
end
