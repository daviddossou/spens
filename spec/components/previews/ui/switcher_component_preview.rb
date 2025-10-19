# frozen_string_literal: true

class Ui::SwitcherComponentPreview < ViewComponent::Preview
  # Simple string options with current selection
  def default
    render Ui::SwitcherComponent.new(
      options: ["Option 1", "Option 2", "Option 3"],
      current: "Option 2"
    )
  end

  # Hash-based options with URLs and data attributes
  def with_hash_options
    render Ui::SwitcherComponent.new(
      options: [
        { text: "Home", value: "home", url: "/", data: { controller: "navigation" } },
        { text: "About", value: "about", url: "/about" },
        { text: "Contact", value: "contact", url: "/contact" }
      ],
      current: "about"
    )
  end

  # Language switcher example (like the original use case)
  def language_switcher
    render Ui::SwitcherComponent.new(
      options: [
        { text: "English", value: "en", url: "/?locale=en" },
        { text: "Français", value: "fr", url: "/?locale=fr" }
      ],
      current: "en",
      css_class: "inline-flex rounded-md"
    )
  end

  # No current selection (all inactive)
  def no_selection
    render Ui::SwitcherComponent.new(
      options: ["Draft", "Published", "Archived"],
      current: nil
    )
  end

  # Single option
  def single_option
    render Ui::SwitcherComponent.new(
      options: ["Only Option"],
      current: "Only Option"
    )
  end

  # Custom CSS class
  def with_custom_class
    render Ui::SwitcherComponent.new(
      options: ["Small", "Medium", "Large"],
      current: "Medium",
      css_class: "inline-flex bg-gray-100 rounded-lg p-1"
    )
  end

  # Mixed hash and string options
  def mixed_options
    render Ui::SwitcherComponent.new(
      options: [
        { text: "Dashboard", value: "dashboard", url: "/dashboard" },
        "Settings",
        { text: "Profile", value: "profile", url: "/profile" }
      ],
      current: "Settings"
    )
  end

  # Tab-style switcher
  def tab_style
    render Ui::SwitcherComponent.new(
      options: [
        { text: "Overview", value: "overview", url: "#overview" },
        { text: "Analytics", value: "analytics", url: "#analytics" },
        { text: "Reports", value: "reports", url: "#reports" },
        { text: "Settings", value: "settings", url: "#settings" }
      ],
      current: "analytics",
      css_class: "flex border-b"
    )
  end
end
