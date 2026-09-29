# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::LastActivityEstimate do
  let(:user) { create(:user, confirmed_at: nil) }

  # The factory stamps the default space and membership at "now"; age them so they don't win.
  before do
    user.update_columns(current_sign_in_at: nil, last_sign_in_at: nil, last_active_at: nil)
    user.owned_spaces.update_all(updated_at: 1.year.ago)
    user.memberships.update_all(updated_at: 1.year.ago)
  end

  it "falls back to the newest write on owned records" do
    expect(described_class.call(user)).to be_within(1.second).of(1.year.ago)
  end

  it "picks the newest stamp across sign-ins and authored records" do
    user.update_columns(current_sign_in_at: 10.days.ago)
    create(:account, user: user, space: user.owned_spaces.first).update_columns(updated_at: 2.days.ago)

    expect(described_class.call(user)).to be_within(1.second).of(2.days.ago)
  end

  it "prefers last_active_at when it is the newest" do
    user.update_columns(last_active_at: 1.hour.ago)

    expect(described_class.call(user)).to be_within(1.second).of(1.hour.ago)
  end
end
