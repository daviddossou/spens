# frozen_string_literal: true

require "rails_helper"

RSpec.describe Activation do
  let(:user) { create(:user) }

  before do
    allow(Analytics).to receive(:track_at)
    allow(Meta::Activation).to receive(:record)
  end

  it "tracks a milestone once per user and forwards it to Meta" do
    2.times { described_class.record(user, :first_goal) }

    expect(Analytics).to have_received(:track_at).with(nil, user, "activation_first_goal", {}).once
    expect(Meta::Activation).to have_received(:record).with(user, "spens_first_goal").twice
    expect(user.activation_milestones.pluck(:name)).to eq([ "first_goal" ])
  end

  it "backdates a backfilled milestone and keeps it away from Meta" do
    at = 3.months.ago.change(usec: 0)

    described_class.record(user, :first_goal, at: at)

    expect(Analytics).to have_received(:track_at).with(at, user, "activation_first_goal", { backfilled: true })
    expect(Meta::Activation).not_to have_received(:record)
    expect(user.activation_milestones.first.created_at).to eq(at)
  end

  it "rejects an unknown milestone" do
    expect { described_class.record(user, :nope) }.to raise_error(ArgumentError)
  end
end
