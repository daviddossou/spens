# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Cloudflare trusted proxies" do
  def remote_ip_for(remote_addr:, forwarded_for:)
    middleware = ActionDispatch::RemoteIp.new(
      ->(env) { [ 200, {}, [ env["action_dispatch.remote_ip"].to_s ] ] },
      true, Rails.application.config.action_dispatch.trusted_proxies
    )
    env = Rack::MockRequest.env_for("/", "REMOTE_ADDR" => remote_addr, "HTTP_X_FORWARDED_FOR" => forwarded_for)
    middleware.call(env).last.first
  end

  it "resolves the visitor behind Cloudflare and kamal-proxy" do
    expect(remote_ip_for(remote_addr: "172.18.0.2", forwarded_for: "41.79.10.5, 104.16.1.1")).to eq("41.79.10.5")
  end

  it "still resolves the visitor without Cloudflare" do
    expect(remote_ip_for(remote_addr: "172.18.0.2", forwarded_for: "41.79.10.5")).to eq("41.79.10.5")
  end

  it "does not trust an arbitrary forwarded chain" do
    expect(remote_ip_for(remote_addr: "172.18.0.2", forwarded_for: "1.1.1.1, 8.8.8.8")).to eq("8.8.8.8")
  end
end
