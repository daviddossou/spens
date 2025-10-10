# ViewComponent Configuration
ViewComponent::Base.config.view_component_path = "app/components"

# Configure ViewComponent to use custom preview layout
ViewComponent::Base.config.default_preview_layout = "component_preview"

# Enable previews in development
ViewComponent::Base.config.show_previews = Rails.env.development?

# Configure preview paths for organized structure
ViewComponent::Base.config.preview_paths = [ Rails.root.join("spec/components/previews") ]

# Generate preview on component creation
ViewComponent::Base.config.generate.preview = true

# Generate test files
ViewComponent::Base.config.generate.sidecar = true
