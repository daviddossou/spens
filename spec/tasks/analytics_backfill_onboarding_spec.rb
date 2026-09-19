# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "analytics:backfill_onboarding" do
  before(:all) { Rails.application.load_tasks unless Rake::Task.task_defined?("analytics:backfill_onboarding") }

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:client) { instance_double(PostHog::Client, capture: true, identify: true, group_identify: true) }

  before { allow(Analytics).to receive(:client).and_return(client) }

  def run_task
    Rake::Task["analytics:backfill_onboarding"].reenable
    Rake::Task["analytics:backfill_onboarding"].invoke
  end

  it "writes the answers on the person and replays each goal with a stable uuid" do
    space.update!(financial_goals: %w[pay_off_debt], country: "BJ", currency: "XOF")

    uuids = []
    allow(client).to receive(:capture) { |attrs| uuids << attrs[:uuid] }
    2.times { run_task }

    expect(client).to have_received(:identify).with(
      distinct_id: "user_#{user.id}", properties: include("goal_pay_off_debt" => true, country: "BJ")
    ).twice
    expect(client).to have_received(:capture).with(
      include(event: "onboarding_goal_chosen", timestamp: space.created_at,
              properties: include(goal: "pay_off_debt", backfilled: true))
    ).twice
    expect(uuids.uniq.size).to eq(1)
  end
end
