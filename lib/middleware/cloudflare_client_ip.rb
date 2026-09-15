# frozen_string_literal: true

module Middleware
  # kamal-proxy replaces X-Forwarded-For with the address of its own peer, which
  # is a Cloudflare edge now that the proxy is on, so Rails would key rate limits
  # on edge IPs. The visitor travels in CF-Connecting-IP: put it back at the head
  # of the chain, but only when the peer really is Cloudflare, so a request that
  # hits the origin directly cannot spoof its address.
  class CloudflareClientIp
    def initialize(app)
      @app = app
    end

    def call(env)
      visitor = env["HTTP_CF_CONNECTING_IP"]
      peer = env["HTTP_X_FORWARDED_FOR"].to_s.split(",").last&.strip
      env["HTTP_X_FORWARDED_FOR"] = "#{visitor}, #{peer}" if visitor.present? && cloudflare?(peer)
      @app.call(env)
    end

    private

    def cloudflare?(ip)
      return false if ip.blank?

      address = IPAddr.new(ip)
      CLOUDFLARE_IP_RANGES.any? { |range| range.include?(address) }
    rescue IPAddr::Error
      false
    end
  end
end
