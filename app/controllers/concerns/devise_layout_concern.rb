module DeviseLayoutConcern
  extend ActiveSupport::Concern

  included do
    layout :layout_by_resource
  end

  private

  def layout_by_resource
    if devise_controller?
      'auth'
    else
      'application'
    end
  end
end
