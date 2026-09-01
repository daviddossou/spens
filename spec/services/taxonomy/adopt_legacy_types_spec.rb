# frozen_string_literal: true

require "rails_helper"

RSpec.describe Taxonomy::AdoptLegacyTypes do
  before { Taxonomy::SyncNodes.new.call }
  after { TransactionTaxonomy.reload! }

  let(:space) { create(:space) }
  let(:account) { create(:account, name: "Main") }

  # The legacy name the app itself assigned; the map sends it to restaurant_maquis.
  def legacy_type(name: I18n.t("transaction_type_templates.food_restaurant.name", locale: :fr),
                  kind: "expense")
    create(:transaction_type, space: space, kind: kind, name: name, template_key: nil)
  end

  def spend(type, count: 1)
    count.times { create(:transaction, space: space, transaction_type: type, amount: -100) }
  end

  it "adopts a legacy row, keys it and renames it to the current taxonomy name" do
    type = legacy_type
    spend(type, count: 3)

    expect(described_class.new.call.adopted).to eq(1)

    type.reload
    expect(type.template_key).to eq("restaurant_maquis")
    expect(type.name).to eq(TransactionTaxonomy.name("restaurant_maquis"))
    expect(type.transactions.count).to eq(3)
  end

  it "files the adopted row under its taxonomy parent, so a parent budget sees the spend" do
    spend(legacy_type, count: 2)
    described_class.new.call

    adopted = space.transaction_types.find_by(template_key: "restaurant_maquis")
    parent = space.transaction_types.find_by(template_key: "eating_out")

    expect(parent).to be_present
    expect(adopted.parent_id).to eq(parent.id)
    expect(parent.subtree_ids).to include(adopted.id)
  end

  it "merges into the existing row when the space already holds the target, keeping transactions" do
    owner = create(:transaction_type, space: space, kind: "expense",
                   name: TransactionTaxonomy.name("restaurant_maquis"), template_key: "restaurant_maquis")
    legacy = legacy_type
    spend(legacy, count: 4)
    spend(owner, count: 1)

    expect(described_class.new.call.merged).to eq(1)

    expect(TransactionType.where(id: legacy.id)).to be_empty
    expect(owner.reload.transactions.count).to eq(5)
  end

  it "leaves a category the user renamed by hand untouched" do
    mine = create(:transaction_type, space: space, kind: "expense", name: "Chez Tantie Bola")
    spend(mine)

    described_class.new.call

    expect(mine.reload.template_key).to be_nil
    expect(mine.name).to eq("Chez Tantie Bola")
  end

  it "re-parents a keyed row after the taxonomy moved it" do
    # investment_fees moved from savings_investment to transaction_fees.
    stale_parent = create(:transaction_type, space: space, kind: "expense", template_key: "savings_investment",
                          name: TransactionTaxonomy.name("savings_investment"))
    fees = create(:transaction_type, space: space, kind: "expense", template_key: "investment_fees",
                  name: TransactionTaxonomy.name("investment_fees"), parent: stale_parent)

    expect(described_class.new.call.reparented).to be_positive

    expect(fees.reload.parent.template_key).to eq("transaction_fees")
  end

  it "is idempotent" do
    spend(legacy_type, count: 2)
    described_class.new.call
    second = described_class.new.call

    expect([ second.adopted, second.merged, second.reparented ]).to all(eq(0))
  end

  it "never touches a kind the taxonomy does not cover" do
    transfer = create(:transaction_type, space: space, kind: "transfer_out", name: "Décaissement")
    spend(transfer)

    described_class.new.call

    expect(transfer.reload.template_key).to be_nil
  end
end
