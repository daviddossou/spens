# frozen_string_literal: true

module Ui
  # @label Icon
  class IconComponentPreview < ViewComponent::Preview
    # A single icon
    # @param name select { choices: [chevron_right, chevron_down, chevron_left, check, close, plus, arrow_up, arrow_down, refresh, search, shield, pin, lend, borrow, wallet, archive, dots] }
    def default(name: :chevron_right)
      render(Ui::IconComponent.new(name, width: 24, height: 24))
    end

    # Every registered icon with its name
    def all_icons
      render_with_template locals: { names: Ui::IconComponent::ICONS.keys }
    end

    # Thicker stroke and sized through html options
    def thick_stroke
      render(Ui::IconComponent.new(:check, stroke_width: 3, width: 48, height: 48))
    end
  end
end
