require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative "../lib/middleware/reject_malformed_form"
require_relative "../lib/middleware/cloudflare_client_ip"

module Spens
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets middleware tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Malformed form bodies (e.g. a multipart part tagged charset=utf-16le) blow up
    # inside Rack before Rails' own handling; answer 400 instead of raising.
    config.middleware.insert_before Rack::MethodOverride, Middleware::RejectMalformedForm
    config.middleware.insert_before ActionDispatch::RemoteIp, Middleware::CloudflareClientIp

    # Configure Sidekiq as the default job queue
    config.active_job.queue_adapter = :sidekiq

    # i18n configuration
    config.i18n.available_locales = [ :en, :fr ]
    config.i18n.default_locale = :en

    # Solid Errors records exceptions in the dedicated `errors` database (all envs)
    config.solid_errors.connects_to = { database: { writing: :errors } }
  end
end
