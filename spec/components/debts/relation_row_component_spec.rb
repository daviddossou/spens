# frozen_string_literal: true

require "rails_helper"

RSpec.describe Debts::RelationRowComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:lent) { create(:debt, space: space, name: "Myri Diop", total_lent: 100_000, total_reimbursed: 25_000) }

  before { allow(vc_test_controller).to receive(:current_space).and_return(space) }

  def render_row(relation)
    render_inline(described_class.new(relation: relation))
  end

  context "a single loan being repaid" do
    let(:rendered) { render_row(DebtRelation.new(space: space, name: "Myri Diop", debts: [ lent ])) }

    it "links to the debt with initials, name and remaining amount" do
      link = rendered.at_css("a.debt-relation")
      expect(link["href"]).to eq(debt_path(id: lent.id))
      expect(link.at_css(".debt-relation__avatar").text).to eq("MD")
      expect(link.at_css(".debt-relation__avatar")["class"]).to include("debt-relation__avatar--lent")
      expect(link.at_css(".debt-relation__name").text).to eq("Myri Diop")
      expect(link.at_css(".debt-relation__amount").text).to include("75,000")
      expect(link.at_css(".debt-relation__amount")["class"]).to include("debt-relation__amount--lent")
      expect(rendered.css(".debt-relation__tag, .debt-relation__amount-sub")).to be_empty
    end

    it "shows a repayment bar sized to the progress" do
      expect(rendered.at_css(".debt-relation__bar-fill")["style"]).to eq("width: 25%;")
      expect(rendered.at_css(".debt-relation__bar-fill")["class"]).to include("debt-relation__bar-fill--lent")
    end
  end

  it "shows no bar before any repayment" do
    untouched = create(:debt, :borrowed, space: space, name: "Ali", total_lent: 5_000)
    rendered = render_row(DebtRelation.new(space: space, name: "Ali", debts: [ untouched ]))
    expect(rendered.css(".debt-relation__bar")).to be_empty
    expect(rendered.at_css(".debt-relation__amount")["class"]).to include("debt-relation__amount--borrowed")
  end

  context "a two-way relation" do
    let(:borrowed) { create(:debt, :borrowed, space: space, name: "Myri Diop", total_lent: 30_000) }
    let(:rendered) { render_row(DebtRelation.new(space: space, name: "Myri Diop", debts: [ lent, borrowed ])) }

    it "tags it, spells both sides and shows the net" do
      expect(rendered.at_css(".debt-relation__tag").text).to eq("Two-way")
      sub = rendered.at_css(".debt-relation__sub").text.squish
      expect(sub).to include("They owe you 75,000")
      expect(sub).to include("you owe them 30,000")
      expect(rendered.at_css(".debt-relation__amount").text).to include("45,000")
      expect(rendered.at_css(".debt-relation__amount-sub").text).to eq("net")
      expect(rendered.css(".debt-relation__bar")).to be_empty
      expect(rendered.at_css("a.debt-relation")["href"]).to eq(debt_path(id: lent.id))
      expect(rendered.text).not_to include("translation missing")
    end
  end
end
