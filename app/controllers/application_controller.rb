class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Include concerns for better organization
  include DeviseConfiguration
  include InternationalizationSupport
  include DeviseLayoutConcern
  include OnboardingRedirection

  protected

  # Redirect with Turbo full page reload
  # Use this for redirects after form submissions that should break out of Turbo Frames/Streams
  # and perform a complete page navigation (e.g., onboarding completion, major context changes)
  def redirect_with_reload_to(options = {}, response_options = {})
    response.headers["Turbo-Visit-Control"] = "reload"

    # Force format to HTML to prevent Turbo from maintaining TURBO_STREAM through redirect
    url = if options.is_a?(String)
            # If it's already a path string, append format parameter
            separator = options.include?('?') ? '&' : '?'
            "#{options}#{separator}format=html"
          else
            # If it's a hash of URL options, merge format
            url_for(options.merge(format: :html, only_path: true))
          end

    redirect_to(url, response_options)
  end
end
