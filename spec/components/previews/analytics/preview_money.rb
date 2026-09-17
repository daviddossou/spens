# frozen_string_literal: true

require "ostruct"

module Analytics
  # Previews render without a signed-in user, so `money` has no `current_space`.
  # This context carries the money helpers only and is handed to the component
  # (and, through ViewComponent, to the components it renders) as `helpers`.
  module PreviewMoney
    class Context
      include ActionView::Helpers::NumberHelper
      include MoneyHelper

      def current_space
        @current_space ||= OpenStruct.new(currency: "XOF")
      end
    end

    def with_money(component)
      component.set_original_view_context(Context.new)
      component
    end
  end
end
