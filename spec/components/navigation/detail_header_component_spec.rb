# frozen_string_literal: true

require "rails_helper"

RSpec.describe Navigation::DetailHeaderComponent, type: :component do
  it "renders a centred detail header with a localized back link" do
    rendered = render_inline(described_class.new(back_url: "/debts", title: "Georges"))
    header = rendered.at_css("header")
    expect(header["class"].split).to contain_exactly("app-header", "app-header--detail")
    back = header.at_css("a.app-header__back")
    expect(back["href"]).to eq("/debts")
    expect(back["aria-label"]).to eq(I18n.t("navigation.header.back"))
    expect(back.at_css("svg path")["d"]).to eq("M15 19l-7-7 7-7")
    expect(header.at_css("h1.app-header__title").text).to eq("Georges")
    expect(header.css(".app-header__subtitle")).to be_empty
    expect(header.at_css(".app-header__right").text.strip).to eq("")
    expect(rendered.to_html).not_to include("translation_missing")
  end

  it "uses a custom back label and shows the subtitle" do
    rendered = render_inline(described_class.new(back_url: "/goals", title: "Trip", back_label: "Back to goals", subtitle: "Savings"))
    expect(rendered.at_css("a.app-header__back")["aria-label"]).to eq("Back to goals")
    expect(rendered.at_css(".app-header__subtitle").text).to eq("Savings")
  end

  it "aligns the title to the left on request" do
    rendered = render_inline(described_class.new(back_url: "/", title: "T", align: :left))
    expect(rendered.at_css("header")["class"]).to include("app-header--detail-left")
  end

  it "renders the action slot on the right" do
    rendered = render_inline(described_class.new(back_url: "/", title: "T")) do |header|
      header.with_action { '<button class="menu">⋯</button>'.html_safe }
    end
    expect(rendered.at_css(".app-header__right button.menu")).to be_present
  end
end
