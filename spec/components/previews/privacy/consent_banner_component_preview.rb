# frozen_string_literal: true

module Privacy
  # @label Consent banner
  class ConsentBannerComponentPreview < ViewComponent::Preview
    # The banner as an undecided visitor sees it. It only exists while a pixel
    # is configured and no choice is stored: the template stands both in.
    def default
      render_with_template(locals: { component: with_undecided_visitor(Privacy::ConsentBannerComponent.new) })
    end

    private

    def with_undecided_visitor(component)
      context = Object.new
      context.define_singleton_method(:meta_consent_state) { nil }
      component.set_original_view_context(context)
      component
    end
  end
end
