# frozen_string_literal: true

class Ui::ActionMenuComponent < ViewComponent::Base
  def initialize(label:, classes: nil, trigger_class: "header-menu__trigger", panel_class: "header-menu__panel")
    @label = label
    @classes = classes
    @trigger_class = trigger_class
    @panel_class = panel_class
  end

  private

  attr_reader :label, :classes, :trigger_class, :panel_class

  renders_one :trigger
end
