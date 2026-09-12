# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "accounts:normalize_balances" do
  before(:all) { Rails.application.load_tasks unless Rake::Task.task_defined?("accounts:normalize_balances") }

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  def run_task
    Rake::Task["accounts:normalize_balances"].reenable
    Rake::Task["accounts:normalize_balances"].invoke
  end

  it "clears sub-cent drift and negative zero, leaving clean balances alone" do
    drifted = create(:account, space: space, name: "Cash")
    drifted.update_columns(balance: -2.8421709430404007e-14)
    negative_zero = create(:account, space: space, name: "Wise")
    negative_zero.update_columns(balance: -0.0)
    debit = create(:account, space: space, name: "Card")
    debit.update_columns(balance: -12.345)
    clean = create(:account, space: space, name: "Bank", balance: 100.5)
    clean_updated_at = clean.reload.updated_at

    run_task

    expect(drifted.reload.balance).to eq(0.0)
    expect(drifted.balance.to_s).to eq("0.0")
    expect(negative_zero.reload.balance.to_s).to eq("0.0")
    expect(debit.reload.balance).to eq(-12.35)
    expect(clean.reload.updated_at).to eq(clean_updated_at)
  end
end
