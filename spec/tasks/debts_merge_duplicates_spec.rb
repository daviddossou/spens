# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "debts:merge_duplicate_names" do
  before(:all) { Rails.application.load_tasks unless Rake::Task.task_defined?("debts:merge_duplicate_names") }

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  def run_task
    Rake::Task["debts:merge_duplicate_names"].reenable
    Rake::Task["debts:merge_duplicate_names"].invoke
  end

  it "merges same-direction duplicates of one person, re-pointing transactions" do
    keeper = create(:debt, :paid, space: space, name: "Doris", direction: "lent",
                                  total_lent: 41.90, total_reimbursed: 41.90, created_at: 2.years.ago)
    dupe = create(:debt, :paid, space: space, name: "doris ", direction: "lent",
                                total_lent: 2209.76, total_reimbursed: 2209.76)
    # A write-off type posts nothing to the ledger, keeping the totals pristine.
    writeoff = create(:transaction_type, space: space, kind: "debt_writeoff", name: "Write-off")
    txn = create(:transaction, space: space, debt: dupe, transaction_type: writeoff)

    expect { run_task }.to change(Debt, :count).by(-1)

    keeper.reload
    expect(keeper.total_lent).to eq(2251.66)
    expect(keeper.total_reimbursed).to eq(2251.66)
    expect(keeper.status).to eq("paid")
    expect(txn.reload.debt_id).to eq(keeper.id)
  end

  it "keeps the merged debt ongoing when one side still is, with the summed remainder" do
    create(:debt, :paid, space: space, name: "David", direction: "lent",
                         total_lent: 218.37, total_reimbursed: 218.37, created_at: 2.years.ago)
    create(:debt, space: space, name: "david", direction: "lent",
                  total_lent: 53.50, total_reimbursed: 0, status: "ongoing")

    run_task

    merged = space.debts.where("lower(name) = 'david'").sole
    expect(merged.status).to eq("ongoing")
    expect(merged.remaining_balance).to eq(53.50)
  end

  it "never merges across directions or people, and is idempotent" do
    create(:debt, space: space, name: "Gilchrist", direction: "lent", total_lent: 35_000)
    create(:debt, :borrowed, space: space, name: "Gilchrist", direction: "borrowed", total_lent: 150_000)
    create(:debt, space: space, name: "Mariam", direction: "lent", total_lent: 80_000)

    expect { run_task }.not_to change(Debt, :count)
    expect { run_task }.not_to change(Debt, :count)
  end
end
