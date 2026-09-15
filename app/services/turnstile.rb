# frozen_string_literal: true

# Server-side check of a Cloudflare Turnstile token. Fails closed on a bad,
# missing or reused token; fails open (with a warning) when siteverify itself
# is unreachable, so a Cloudflare outage never blocks sign-ups.
module Turnstile
  module_function

  VERIFY_URI = URI("https://challenges.cloudflare.com/turnstile/v0/siteverify")
  TIMEOUT = 5

  Result = Struct.new(:success, :error_codes) do
    def success? = success
  end

  def enabled?
    config[:enabled]
  end

  def site_key
    config[:site_key]
  end

  def verify(token, ip: nil)
    return Result.new(true, []) unless enabled?
    return Result.new(false, [ "missing-input-response" ]) if token.blank?

    body = siteverify(response: token, secret: config[:secret_key], remoteip: ip)
    return Result.new(true, []) if body["success"]

    Result.new(false, Array(body["error-codes"]))
  rescue Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError, JSON::ParserError, Net::HTTPError => e
    Rails.logger.warn("[Turnstile] siteverify unreachable (#{e.class}: #{e.message}), letting the request through")
    Result.new(true, [ "siteverify-unreachable" ])
  end

  # Parsed siteverify response; non-2xx raises so it counts as an outage.
  def siteverify(params)
    http = Net::HTTP.new(VERIFY_URI.host, VERIFY_URI.port)
    http.use_ssl = true
    http.open_timeout = http.read_timeout = TIMEOUT
    response = http.post(VERIFY_URI.path, URI.encode_www_form(params.compact))
    raise Net::HTTPError.new("siteverify #{response.code}", response) unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  def config
    Rails.application.config.x.turnstile
  end
end
