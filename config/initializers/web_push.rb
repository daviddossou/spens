# frozen_string_literal: true

# VAPID keys for Web Push (the evening reminder). ENV wins over credentials
# (`webpush.public_key` / `webpush.private_key`). Generate a pair with
# `WebPush.generate_key`. Development keeps its own pair in tmp/ so push works with no setup;
# without keys the app falls back to e-mail reminders only.
keys = {
  public_key: ENV["VAPID_PUBLIC_KEY"].presence || Rails.application.credentials.dig(:webpush, :public_key),
  private_key: ENV["VAPID_PRIVATE_KEY"].presence || Rails.application.credentials.dig(:webpush, :private_key)
}

if keys.values.any?(&:blank?) && Rails.env.development?
  path = Rails.root.join("tmp/web_push_vapid.json")
  unless path.exist?
    pair = WebPush.generate_key
    path.write({ public_key: pair.public_key, private_key: pair.private_key }.to_json)
  end
  keys = JSON.parse(path.read, symbolize_names: true)
end

Rails.application.config.x.web_push = keys.values.all?(&:present?) ? keys.merge(subject: "mailto:contact@spens.me") : nil
