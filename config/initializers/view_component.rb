ViewComponent::Base.config.view_component_path = "app/components"

# Configure ViewComponent to use Stimulus if needed
ViewComponent::Base.config.default_preview_layout = "component_preview"

# Enable previews in development
ViewComponent::Base.config.show_previews = Rails.env.development?
