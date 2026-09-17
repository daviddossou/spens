# frozen_string_literal: true

# "Bring it back" card: a title, a line of context and one outlined action that
# undoes a dated decision (a written-off debt, a month's exception to the rule).
class Ui::RevertPromptComponent < ViewComponent::Base
  def initialize(title:, subtitle:, button_text:, url:, method: :post, classes: nil)
    @title = title
    @subtitle = subtitle
    @button_text = button_text
    @url = url
    @method = method
    @classes = classes
  end

  private

  attr_reader :title, :subtitle, :button_text, :url, :method, :classes
end
