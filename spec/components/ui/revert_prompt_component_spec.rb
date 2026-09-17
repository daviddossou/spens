# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::RevertPromptComponent, type: :component do
  let(:rendered) do
    render_inline(described_class.new(
      title: "Bring Georges back?", subtitle: "The debt reopens as it was.",
      button_text: "Reactivate", url: "/debts/1/write_off", method: :delete
    ))
  end

  it "renders the title and the context line" do
    expect(rendered.at_css(".debt-reactivate__title").text).to eq("Bring Georges back?")
    expect(rendered.at_css(".debt-reactivate__sub").text).to eq("The debt reopens as it was.")
  end

  it "renders an outlined action link carrying the turbo method" do
    link = rendered.at_css("a.debt-reactivate__btn")
    expect(link["href"]).to eq("/debts/1/write_off")
    expect(link["data-turbo-method"]).to eq("delete")
    expect(link["class"]).to include("btn-outline-primary")
    expect(link.text.strip).to eq("Reactivate")
  end

  it "posts by default and appends extra classes" do
    rendered = render_inline(described_class.new(
      title: "Back to the rule", subtitle: "Sub", button_text: "Revert", url: "/budget_entries/1/revert", classes: "budget-scope__revert"
    ))
    expect(rendered.at_css(".debt-reactivate")["class"]).to eq("debt-reactivate budget-scope__revert")
    expect(rendered.at_css("a")["data-turbo-method"]).to eq("post")
  end
end
