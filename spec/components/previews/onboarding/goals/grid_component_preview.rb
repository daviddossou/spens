# frozen_string_literal: true
require 'ostruct'

module Onboarding
  module Goals
    class GridComponentPreview < ViewComponent::Preview
      SAMPLE_GOALS = [
        { key: 'save_for_emergency', name: 'Build Emergency Fund', description: 'Save for unexpected events' },
        { key: 'pay_off_debt', name: 'Pay Off Debt', description: 'Eliminate liabilities' },
        { key: 'build_wealth', name: 'Build Wealth', description: 'Grow assets over time' }
      ].freeze

      def default
        model = PreviewFinancialGoalModel.new(SAMPLE_GOALS, ['save_for_emergency'])
        render GridComponent.new(form_builder: preview_form_builder, model: model)
      end

      def none_selected
        model = PreviewFinancialGoalModel.new(SAMPLE_GOALS, [])
        render GridComponent.new(form_builder: preview_form_builder, model: model)
      end

      class PreviewFinancialGoalModel
        attr_reader :financial_goals

        def initialize(goals, selected)
          @available = goals
          @financial_goals = selected
        end

        def available_goals
          @available
        end
      end

      # Minimal form builder used only for previews (mirrors methods used by checkbox component)
      class PreviewFormBuilder
        def check_box(field, options = {}, checked_value = '1', _unchecked_value = '0')
          classes = options[:class]
          checked_attr = options[:checked] ? 'checked="checked"' : ''
          multiple_attr = options[:multiple] ? 'multiple="multiple"' : ''
          %(<input type="checkbox" name="#{field}" value="#{checked_value}" class="#{classes}" #{checked_attr} #{multiple_attr} />).html_safe
        end

        def label(field, text = nil, options = {})
          text ||= field.to_s.humanize
            %(<label for="#{field}" class="#{options[:class]}">#{text}</label>).html_safe
        end

        class ErrorsDouble
          def key?(_field); false; end
          def full_messages_for(_field); []; end
        end

        def object
          OpenStruct.new(errors: ErrorsDouble.new)
        end
      end

      private

      def preview_form_builder
        PreviewFormBuilder.new
      end
    end
  end
end
