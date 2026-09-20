# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "activation:repair_first_transaction" do
  before(:all) { Rails.application.load_tasks unless Rake::Task.task_defined?("activation:repair_first_transaction") }

  let(:client) { instance_double(PostHog::Client, capture: true) }

  before { allow(Analytics).to receive(:client).and_return(client) }

  def run_task
    Rake::Task["activation:repair_first_transaction"].reenable
    Rake::Task["activation:repair_first_transaction"].invoke
  end

  def opening_balance_for(user)
    type = create(:transaction_type, space: user.spaces.first, kind: "initial_balance")
    create(:transaction, space: user.spaces.first, user: user, transaction_type: type)
  end

  it "never counts an opening balance as the first transaction" do
    user = create(:user)

    expect { opening_balance_for(user) }.not_to change { ActivationMilestone.where(name: "first_transaction").count }
  end

  it "drops the milestone of users who only have opening balances, with its Meta conversion" do
    user = create(:user)
    opening_balance_for(user)
    ActivationMilestone.create!(user: user, name: "first_transaction")
    MetaConversion.create!(user: user, event_name: "spens_first_transaction", event_id: SecureRandom.uuid)

    run_task

    expect(ActivationMilestone.where(user: user, name: "first_transaction")).to be_empty
    expect(MetaConversion.where(user: user)).to be_empty
    expect(client).not_to have_received(:capture).with(include(event: "activation_first_transaction"))
  end

  it "re-dates the milestone of real users and sends one corrected event, however often it runs" do
    user = create(:user)
    opening_balance_for(user)
    real = travel_to(2.days.from_now) { create(:transaction, space: user.spaces.first, user: user) }
    ActivationMilestone.find_by!(user: user, name: "first_transaction").update_columns(created_at: 5.days.ago)

    uuids = []
    allow(client).to receive(:capture) { |attrs| uuids << attrs[:uuid] }
    2.times { run_task }

    expect(ActivationMilestone.find_by!(user: user, name: "first_transaction").created_at).to be_within(1.second).of(real.created_at)
    expect(client).to have_received(:capture).with(
      include(event: "activation_first_transaction", properties: include(excludes_opening_balance: true, backfilled: true))
    ).twice
    expect(uuids.uniq.size).to eq(1)
  end
end
