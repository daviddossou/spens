# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::EmptyStateComponent, type: :component do
  it "wraps the block content in the default empty-state class" do
    rendered = render_inline(described_class.new) { "<p>Nothing yet</p>".html_safe }
    expect(rendered.at_css("div.empty-state p").text).to eq("Nothing yet")
  end

  it "uses the given classes instead of the default" do
    rendered = render_inline(described_class.new(classes: "goals-empty")) { "Empty" }
    div = rendered.at_css("div")
    expect(div["class"]).to eq("goals-empty")
    expect(div.text).to eq("Empty")
  end
end
