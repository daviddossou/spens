# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::FactRowComponent, type: :component do
  context "with a url" do
    let(:rendered) { render_inline(described_class.new(label: "Category", value: "Groceries", url: "/transactions/1/facts/category")) }

    it "renders a link into the modal frame with a chevron" do
      link = rendered.at_css("a.movement-facts__row")
      expect(link["href"]).to eq("/transactions/1/facts/category")
      expect(link["data-turbo-frame"]).to eq("modal")
      expect(link.at_css(".movement-facts__label").text).to eq("Category")
      expect(link.at_css(".movement-facts__value").text).to eq("Groceries")
      expect(link.at_css(".movement-facts__chevron")["aria-hidden"]).to eq("true")
    end
  end

  context "with a custom frame" do
    let(:rendered) { render_inline(described_class.new(label: "Account", value: "Wave", url: "/accounts/1", frame: "_top")) }

    it "targets that frame" do
      expect(rendered.at_css("a")["data-turbo-frame"]).to eq("_top")
    end
  end

  context "without a url" do
    let(:rendered) { render_inline(described_class.new(label: "Date", value: "March 5, 2026")) }

    it "renders a static row" do
      expect(rendered.at_css("a")).to be_nil
      row = rendered.at_css(".movement-facts__row--static")
      expect(row.at_css(".movement-facts__label").text).to eq("Date")
      expect(row.at_css(".movement-facts__value").text).to eq("March 5, 2026")
      expect(row.at_css(".movement-facts__chevron")).to be_nil
    end
  end
end
