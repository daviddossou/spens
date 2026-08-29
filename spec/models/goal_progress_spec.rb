# frozen_string_literal: true

require "rails_helper"

RSpec.describe GoalProgress do
  subject(:progress) { described_class.new(goal) }

  let(:goal) do
    instance_double(
      Goal,
      target_amount: target_amount,
      deadline: deadline,
      created_at: created_at,
      current_amount: current,
      target_set?: target_amount.to_f.positive?,
      remaining: (target_amount ? [ target_amount - current, 0 ].max : nil)
    )
  end
  let(:target_amount) { 500_000 }
  let(:deadline) { Date.new(2027, 8, 1) }
  let(:created_at) { Time.zone.local(2026, 8, 1) }
  let(:current) { 145_000.0 }

  before { travel_to Time.zone.local(2026, 8, 28) }

  describe "#percentage" do
    it "is the saved share of the target, clamped to 0..100" do
      expect(progress.percentage).to eq(29)
    end

    it "is 0 without a target" do
      allow(goal).to receive_messages(target_amount: nil, target_set?: false)
      expect(progress.percentage).to eq(0)
    end
  end

  describe "#monthly" do
    it "spreads the remaining amount over the months through the deadline" do
      # 355_000 remaining over 13 months (Aug 2026 → Aug 2027 inclusive)
      expect(progress.monthly).to eq((355_000.0 / 13).round(2))
    end

    it "is nil without a deadline" do
      allow(goal).to receive(:deadline).and_return(nil)
      expect(progress.monthly).to be_nil
    end

    it "is nil once the target is reached" do
      allow(goal).to receive_messages(current_amount: 500_000.0, remaining: 0)
      expect(progress.monthly).to be_nil
    end
  end

  describe "#status" do
    it "is :on_track when saved keeps pace with time elapsed" do
      # ~7% of the year elapsed, 29% saved → ahead of pace
      expect(progress.status).to eq(:on_track)
    end

    it "is :behind when saved lags the time elapsed" do
      allow(goal).to receive_messages(current_amount: 1_000.0, remaining: 499_000)
      travel_to Time.zone.local(2027, 6, 1) # most of the way to the deadline
      expect(progress.status).to eq(:behind)
    end

    it "is :reached when the target is met" do
      allow(goal).to receive_messages(current_amount: 500_000.0, remaining: 0)
      expect(progress.status).to eq(:reached)
    end

    it "is nil with a target but no deadline to pace against" do
      allow(goal).to receive(:deadline).and_return(nil)
      expect(progress.status).to be_nil
    end
  end
end
