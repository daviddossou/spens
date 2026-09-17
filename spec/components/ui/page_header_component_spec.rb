# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::PageHeaderComponent, type: :component do
  it "renders a header element with the block content" do
    rendered = render_inline(described_class.new) { '<p class="page-header__subtitle">Sub</p>'.html_safe }
    header = rendered.at_css("header")
    expect(header["class"]).to eq("page-header")
    expect(header.at_css(".page-header__subtitle").text).to eq("Sub")
  end

  it "appends extra classes" do
    rendered = render_inline(described_class.new(classes: "debt-form__header")) { "Title" }
    expect(rendered.at_css("header")["class"]).to eq("page-header debt-form__header")
  end
end
