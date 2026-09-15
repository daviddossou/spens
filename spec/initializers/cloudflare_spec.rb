# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Cloudflare client IP" do
  # Same stack as production: CloudflareClientIp in front of RemoteIp.
  def remote_ip_for(remote_addr:, forwarded_for:, cf_connecting_ip: nil)
    remote_ip = ActionDispatch::RemoteIp.new(
      ->(env) { [ 200, {}, [ env["action_dispatch.remote_ip"].to_s ] ] },
      true, Rails.application.config.action_dispatch.trusted_proxies
    )
    env = Rack::MockRequest.env_for("/", "REMOTE_ADDR" => remote_addr, "HTTP_X_FORWARDED_FOR" => forwarded_for,
                                         "HTTP_CF_CONNECTING_IP" => cf_connecting_ip)
    Middleware::CloudflareClientIp.new(remote_ip).call(env).last.first
  end

  it "resolves the visitor when the edge is the last hop" do
    expect(remote_ip_for(remote_addr: "172.18.0.2", forwarded_for: "141.101.97.83", cf_connecting_ip: "41.79.10.5"))
      .to eq("41.79.10.5")
  end

  it "resolves the visitor when an inner proxy appended itself after the edge" do
    expect(remote_ip_for(remote_addr: "127.0.0.1", forwarded_for: "141.101.97.83, 172.18.0.5", cf_connecting_ip: "41.79.10.5"))
      .to eq("41.79.10.5")
  end

  it "resolves the visitor when the edge is the remote address" do
    expect(remote_ip_for(remote_addr: "141.101.97.83", forwarded_for: nil, cf_connecting_ip: "41.79.10.5"))
      .to eq("41.79.10.5")
  end

  it "ignores CF-Connecting-IP when the peer is not Cloudflare" do
    expect(remote_ip_for(remote_addr: "172.18.0.2", forwarded_for: "8.8.8.8", cf_connecting_ip: "41.79.10.5"))
      .to eq("8.8.8.8")
  end

  it "resolves the visitor from a full forwarded chain" do
    expect(remote_ip_for(remote_addr: "172.18.0.2", forwarded_for: "41.79.10.5, 104.16.1.1")).to eq("41.79.10.5")
  end

  it "still resolves the visitor without Cloudflare" do
    expect(remote_ip_for(remote_addr: "172.18.0.2", forwarded_for: "41.79.10.5")).to eq("41.79.10.5")
  end

  it "does not trust an arbitrary forwarded chain" do
    expect(remote_ip_for(remote_addr: "172.18.0.2", forwarded_for: "1.1.1.1, 8.8.8.8")).to eq("8.8.8.8")
  end
end
