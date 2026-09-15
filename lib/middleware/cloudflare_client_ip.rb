# frozen_string_literal: true

module Middleware
  # Behind Cloudflare the proxies in front of Puma (kamal-proxy, Thruster) rebuild
  # X-Forwarded-For from their own peers, so the chain Rails sees carries a
  # Cloudflare edge but not the visitor. The visitor travels in CF-Connecting-IP:
  # when a Cloudflare address shows up anywhere in the chain, hand that visitor
  # to ActionDispatch::RemoteIp on its own. A request hitting the origin directly
  # never carries a Cloudflare hop (kamal-proxy drops the inbound header), so
  # the header cannot be spoofed.
  class CloudflareClientIp
    def initialize(app)
      @app = app
    end

    def call(env)
      visitor = env["HTTP_CF_CONNECTING_IP"]
      if visitor.present? && via_cloudflare?(env)
        env["HTTP_X_FORWARDED_FOR"] = visitor
        env["HTTP_CLIENT_IP"] = nil
      end
      @app.call(env)
    end

    private

    def via_cloudflare?(env)
      hops = env["HTTP_X_FORWARDED_FOR"].to_s.split(",").map(&:strip) << env["REMOTE_ADDR"].to_s
      hops.any? { |ip| cloudflare?(ip) }
    end

    def cloudflare?(ip)
      return false if ip.blank?

      address = IPAddr.new(ip)
      CLOUDFLARE_IP_RANGES.any? { |range| range.include?(address) }
    rescue IPAddr::Error
      false
    end
  end
end
