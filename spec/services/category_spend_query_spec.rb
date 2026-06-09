# frozen_string_literal: true

require "rails_helper"

RSpec.describe CategorySpendQuery do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  def type(name)
    FindOrCreateTransactionTypeService.new(space, name, "expense").call
  end

  def expense(transaction_type, amount)
    create(:transaction, space: space, transaction_type: transaction_type, amount: amount)
  end

  it "rolls subcategories up to their parent" do
    expense(type("🛵 Moto-taxi (Zem)"), 1000)
    expense(type("⛽ Fuel"), 500)
    expense(type("🛒 Groceries"), 800)

    result = described_class.new(space.transactions).call

    expect(result[TransactionTaxonomy.name("transport")]).to eq(1500)
    expect(result[TransactionTaxonomy.name("food_groceries")]).to eq(800)
  end

  it "drills a parent into its subcategories" do
    expense(type("🛵 Moto-taxi (Zem)"), 1000)
    expense(type("⛽ Fuel"), 500)

    result = described_class.new(space.transactions, drill: TransactionTaxonomy.name("transport")).call

    expect(result).to eq(
      TransactionTaxonomy.name("moto_taxi") => 1000,
      TransactionTaxonomy.name("fuel") => 500
    )
  end

  it "keeps an un-parented custom category as its own slice" do
    expense(type("My Weird Thing"), 300)

    result = described_class.new(space.transactions).call

    expect(result["My Weird Thing"]).to eq(300)
  end
end
