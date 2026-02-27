module DeviseLayoutConcern
  extend ActiveSupport::Concern

  included do
    layout :layout_by_resource
  end

  private

  def layout_by_resource
    if devise_controller?
      # Signed-in users editing their profile use the main app layout
      if user_signed_in? && controller_name == "registrations" && action_name.in?(%w[edit update])
        "application"
      else
        "auth"
      end
    else
      "application"
    end
  end
end
