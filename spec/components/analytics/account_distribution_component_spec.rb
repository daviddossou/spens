# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analytics::AccountDistributionComponent, type: :component do
  before { stub_current_space(build_stubbed(:space, currency: "XOF")) }

  def account(name, balance)
    double(name: name, balance: balance)
  end

  let(:accounts) { [ account("Bank", 600.0), account("Cash", 400.0) ] }
  let(:rendered) { render_inline(described_class.new(accounts: accounts)) }

  context "without accounts" do
    let(:accounts) { [] }

    it "renders nothing" do
      expect(rendered.to_html.strip).to be_empty
    end
  end

  it "titles the card and links to the accounts page at the top level" do
    expect(rendered.at_css(".analyses-card__title").text).to include("Where your money is")
    link = rendered.at_css("a.analyses-card__link")
    expect(link["href"]).to eq("/accounts")
    expect(link["data-turbo-frame"]).to eq("_top")
  end

  it "stacks one decorative segment per account, sized by its share" do
    stack = rendered.at_css(".analyses-stack")
    expect(stack["aria-hidden"]).to eq("true")
    widths = stack.css(".analyses-stack__seg").map { |seg| seg["style"][/width: ([\d.]+)%/, 1] }
    expect(widths).to eq([ "60.0", "40.0" ])
  end

  it "lists each account with its balance" do
    expect(rendered.css(".analyses-slim__name").map(&:text)).to eq([ "Bank", "Cash" ])
    expect(rendered.css(".analyses-slim__amount").first.text).to include("600")
    expect(rendered.css(".analyses-slim__amount").first.text).to include("FCFA")
  end

  context "with more than three accounts" do
    let(:accounts) do
      [ account("A", 500.0), account("B", 400.0), account("C", 300.0), account("D", 200.0), account("E", 100.0) ]
    end

    it "shows the first three and folds the rest into one muted row" do
      rows = rendered.css(".analyses-slim")
      expect(rows.size).to eq(4)
      expect(rows.css(".analyses-slim__name").map(&:text).first(3)).to eq([ "A", "B", "C" ])
      muted = rendered.at_css(".analyses-slim--muted")
      expect(muted.at_css(".analyses-slim__name").text).to eq("2 other accounts")
      expect(muted.at_css(".analyses-slim__amount").text).to include("300")
    end

    it "still draws every segment" do
      expect(rendered.css(".analyses-stack__seg").size).to eq(5)
    end
  end
end
