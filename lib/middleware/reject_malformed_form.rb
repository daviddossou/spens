# frozen_string_literal: true

module Middleware
  # Rack parses form bodies lazily and raises on ones it can't handle (e.g. a
  # multipart part tagged charset=utf-16le), which would otherwise surface as a
  # 500 from Rack::MethodOverride. Parse eagerly and answer 400 instead.
  class RejectMalformedForm
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      request.POST if request.form_data? || request.parseable_data?
      @app.call(env)
    rescue Encoding::CompatibilityError
      [ 400, { "content-type" => "text/plain" }, [ "Bad Request" ] ]
    end
  end
end
