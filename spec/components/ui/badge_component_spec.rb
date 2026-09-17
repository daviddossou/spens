# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::BadgeComponent, type: :component do
  it "renders the positional text in a span carrying only the page class" do
    rendered = render_inline(described_class.new("Pending", classes: "member-card__badge member-card__badge--pending"))
    span = rendered.at_css("span")
    expect(span.text).to eq("Pending")
    expect(span["class"]).to eq("member-card__badge member-card__badge--pending")
  end

  it "prefers block content over the positional text" do
    rendered = render_inline(described_class.new("Ignored", classes: "tag")) { "Owner" }
    expect(rendered.at_css("span").text).to eq("Owner")
  end

  it "maps a known tone to the generic badge palette" do
    rendered = render_inline(described_class.new("Late", tone: :danger))
    expect(rendered.at_css("span")["class"]).to eq("badge badge--danger")
  end

  it "falls back to the neutral tone for an unknown one and keeps the page class" do
    rendered = render_inline(described_class.new("Odd", tone: :fuchsia, classes: "debt-relation__tag"))
    expect(rendered.at_css("span")["class"]).to eq("badge badge--neutral debt-relation__tag")
  end

  it "omits the class attribute without tone nor classes and forwards html options" do
    rendered = render_inline(described_class.new("Plain", id: "status", data: { role: "status" }))
    span = rendered.at_css("span")
    expect(span["class"]).to be_nil
    expect(span["id"]).to eq("status")
    expect(span["data-role"]).to eq("status")
  end

  it "lists the supported tones" do
    expect(described_class::TONES).to eq(%i[neutral success warning danger info])
  end
end
