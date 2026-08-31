# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "transactions:convert_onboarding_initial_balances" do
  before(:all) { Rails.application.load_tasks unless Rake::Task.task_defined?("transactions:convert_onboarding_initial_balances") }

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:account) { create(:account, space: space, name: "Banque") }

  def run_task
    Rake::Task["transactions:convert_onboarding_initial_balances"].reenable
    Rake::Task["transactions:convert_onboarding_initial_balances"].invoke
  end

  it "re-kinds orphan onboarding legs without touching balances or real transfers" do
    transfer_in = create(:transaction_type, space: space, kind: "transfer_in", name: "Transfer In")
    orphan = create(:transaction, space: space, account: account, transaction_type: transfer_in,
                                  amount: 105_000, transfer_group_id: nil,
                                  description: I18n.t("onboarding.account_setups.initial_balance_description", account_name: "Banque", locale: :fr))
    paired = create(:transaction, space: space, account: account, transaction_type: transfer_in,
                                  amount: 20_000, transfer_group_id: SecureRandom.uuid,
                                  description: "Banque ⬅️ Caisse")
    balance_before = account.reload.balance

    run_task

    expect(orphan.reload.transaction_type.kind).to eq("initial_balance")
    expect(paired.reload.transaction_type.kind).to eq("transfer_in")
    expect(account.reload.balance).to eq(balance_before)
    expect(MovementRow.new(orphan.reload).out_of_totals?).to be(true)
  end
end
