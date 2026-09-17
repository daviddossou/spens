# frozen_string_literal: true

require "rails_helper"

RSpec.describe Forms::ErrorsComponent, type: :component do
  let(:user) do
    User.new.tap do |u|
      u.errors.add(:email, :blank)
      u.errors.add(:first_name, "is too plain")
    end
  end

  it "renders nothing without errors" do
    expect(render_inline(described_class.new(object: User.new)).to_html.strip).to eq("")
  end

  it "renders nothing for a nil object in compact mode" do
    expect(render_inline(described_class.new(object: nil)).to_html.strip).to eq("")
  end

  it "lists the full messages in compact mode" do
    rendered = render_inline(described_class.new(object: user))
    items = rendered.css(".error-messages li").map(&:text)
    expect(items).to eq(user.errors.full_messages)
    expect(rendered.css("#error_explanation")).to be_empty
  end

  it "renders the detailed box with a localized heading and one item per error" do
    rendered = render_inline(described_class.new(object: user, detailed: true))
    box = rendered.at_css("#error_explanation")
    expect(box["data-turbo-cache"]).to eq("false")
    expect(box.at_css("h3").text.strip).to eq(
      I18n.t("errors.messages.not_saved", count: 2, resource: User.model_name.human.downcase)
    )
    expect(box.css("li").map(&:text)).to eq(user.errors.full_messages)
    expect(rendered.to_html).not_to include("translation_missing")
  end
end
