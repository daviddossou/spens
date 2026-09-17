# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::SearchComponent, type: :component do
  let(:query) { nil }
  let(:rendered) { render_inline(described_class.new(query: query)) }
  let(:form) { rendered.at_css("form.transactions-search") }
  let(:input) { form.at_css("input[name='q']") }

  it "searches the dashboard with GET inside the timeline frame" do
    expect(form["action"]).to eq("/dashboard")
    expect(form["method"]).to eq("get")
    expect(form["role"]).to eq("search")
    expect(form["data-controller"]).to eq("search-form sticky")
    expect(form["data-sticky-stuck-class"]).to eq("is-stuck")
    expect(form["data-turbo-frame"]).to eq("transactions_timeline")
    expect(form["data-turbo-action"]).to eq("advance")
  end

  it "renders a labelled search field wired to the controller" do
    expect(input["type"]).to eq("search")
    expect(input["value"]).to be_nil
    expect(input["placeholder"]).to eq("Search transactions…")
    expect(input["aria-label"]).to eq("Search transactions by description, category or amount")
    expect(input["autocomplete"]).to eq("off")
    expect(input["data-search-form-target"]).to eq("input")
    expect(input["data-action"]).to eq("input->search-form#search keydown.esc->search-form#clear")
  end

  it "has a hidden clear button" do
    clear = form.at_css("button.transactions-search__clear")
    expect(clear["type"]).to eq("button")
    expect(clear["class"]).to include("hidden")
    expect(clear["aria-label"]).to eq("Clear search")
    expect(clear["data-search-form-target"]).to eq("clear")
    expect(clear["data-action"]).to eq("search-form#clear")
    expect(clear.at_css("svg")).to be_present
  end

  context "with a query" do
    let(:query) { "zem" }

    it "keeps it in the field" do
      expect(input["value"]).to eq("zem")
    end
  end
end
