# frozen_string_literal: true

module Pwa
  # @label Install banner
  class InstallBannerComponentPreview < ViewComponent::Preview
    # As shipped: hidden until the install controller reveals it
    def default
      render Pwa::InstallBannerComponent.new
    end

    # Forced visible, with the install button
    def revealed
      render_with_template(locals: { ios: false })
    end

    # Forced visible on iOS: the share steps replace the button
    def revealed_ios
      render_with_template(template: "pwa/install_banner_component_preview/revealed", locals: { ios: true })
    end
  end
end
