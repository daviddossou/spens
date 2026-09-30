# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityStamping, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }

  before do
    allow(Brevo).to receive(:upsert_contact_later)
    sign_in user, scope: :user
  end

  it "stamps last_active_at and mirrors the day to Brevo on the first request" do
    travel_to Time.zone.parse("2026-09-29 10:00") do
      get dashboard_path

      expect(user.reload.last_active_at).to eq(Time.current)
      expect(Brevo).to have_received(:upsert_contact_later)
        .with(email: user.email, attributes: { LAST_ACTIVE_AT: "2026-09-29" })
    end
  end

  it "does not write again within the hour" do
    user.update_column(:last_active_at, 20.minutes.ago)

    expect { get dashboard_path }.not_to(change { user.reload.last_active_at })
    expect(Brevo).not_to have_received(:upsert_contact_later)
  end

  it "refreshes the stamp after an hour without telling Brevo on the same day" do
    travel_to Time.zone.parse("2026-09-29 15:00") do
      user.update_column(:last_active_at, 2.hours.ago)

      get dashboard_path

      expect(user.reload.last_active_at).to eq(Time.current)
      expect(Brevo).not_to have_received(:upsert_contact_later)
    end
  end

  it "leaves the impersonated user untouched" do
    admin = create(:user, admin: true)
    sign_in admin, scope: :user
    post impersonate_admin_user_path(id: user.id)

    get dashboard_path

    expect(user.reload.last_active_at).to be_nil
  end
end
