# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Analytics tracking", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:client) { instance_double(PostHog::Client, capture: true, identify: true, group_identify: true) }

  before { allow(Analytics).to receive(:client).and_return(client) }

  it "tracks app_opened once a day per session" do
    sign_in user, scope: :user

    2.times { get dashboard_path }
    expect(client).to have_received(:capture).with(hash_including(event: "app_opened")).once

    travel_to 1.day.from_now do
      get dashboard_path
    end
    expect(client).to have_received(:capture).with(hash_including(event: "app_opened")).twice
  end

  it "sends nothing while an admin impersonates" do
    sign_in create(:user, :admin), scope: :user
    post impersonate_admin_user_path(id: user.id)

    get dashboard_path
    expect(client).not_to have_received(:capture).with(hash_including(distinct_id: "user_#{user.id}"))
  end

  it "asks the browser to forget the PostHog identity on sign-out" do
    sign_in user, scope: :user

    delete destroy_user_session_path
    expect(cookies[:ph_reset]).to eq("1")
  end
end
