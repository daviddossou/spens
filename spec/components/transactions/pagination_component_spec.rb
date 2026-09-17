# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::PaginationComponent, type: :component do
  context "with more pages" do
    let(:rendered) { render_inline(described_class.new(has_more: true)) }

    it "renders the hidden spinner wired to the infinite-scroll controller" do
      spinner = rendered.at_css("#loading-spinner")
      expect(spinner["data-infinite-scroll-target"]).to eq("spinner")
      expect(spinner["class"]).to include("hidden")
      expect(spinner.at_css(".dashboard__spinner-text").text).to eq("Loading more...")
    end

    it "renders the load trigger" do
      expect(rendered.at_css("#infinite-scroll-trigger[data-infinite-scroll-target='trigger']")).to be_present
    end
  end

  context "on the last page" do
    let(:rendered) { render_inline(described_class.new(has_more: false)) }

    it "keeps the spinner but drops the trigger" do
      expect(rendered.at_css("#loading-spinner")).to be_present
      expect(rendered.at_css("#infinite-scroll-trigger")).to be_nil
    end
  end
end
