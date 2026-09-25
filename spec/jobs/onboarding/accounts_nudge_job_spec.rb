# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::AccountsNudgeJob do
  it 'delivers the nudges that are due, not the others' do
    due, later = Array.new(2) { create(:user).memberships.first }
    due.update!(accounts_nudge_at: 1.minute.ago)
    later.update!(accounts_nudge_at: 1.hour.from_now)
    delivered = []
    allow(Onboarding::AccountsNudge).to receive(:new) { |m| instance_double(Onboarding::AccountsNudge, deliver: delivered << m) }

    described_class.perform_now

    expect(delivered).to eq([ due ])
  end
end
