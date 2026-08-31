# frozen_string_literal: true

require "rails_helper"

RSpec.describe AnalyticsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:account) { create(:account, user: user) }

  before { sign_in user, scope: :user }

  def spend(amount, name: "Courses X", on: Date.current)
    type = space.transaction_types.find_by(name: name) ||
           create(:transaction_type, space: space, kind: "expense", name: name)
    create(:transaction, space: space, user: user, account: account,
                         transaction_type: type, amount: -amount, transaction_date: on)
  end

  it "requires authentication" do
    sign_out :user
    get analytics_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "defaults to the month range and shows the spent hero" do
    spend(20_000)
    get analytics_path

    expect(response).to be_successful
    expect(assigns(:period).kind).to eq("month")
    expect(response.body).to include(I18n.t("analytics.index.section_spent"))
    expect(response.body).to include("20")
  end

  it "reads the range param and rejects unknown ones" do
    get analytics_path(range: "three_months")
    expect(assigns(:period).kind).to eq("three_months")

    get analytics_path(range: "hack")
    expect(assigns(:period).kind).to eq("month")
  end

  it "shows the empty state when the period has nothing" do
    get analytics_path
    expect(response.body).to include(I18n.t("analytics.index.empty_title"))
  end

  it "states the moved money apart, never in the spent total" do
    spend(10_000)
    debt_type = create(:transaction_type, space: space, kind: "debt_out", name: "Prêt X")
    create(:transaction, space: space, user: user, account: account,
                         transaction_type: debt_type, amount: -50_000, transaction_date: Date.current)

    get analytics_path
    expect(assigns(:spending).spent_total).to eq(10_000)
    expect(response.body).to include(I18n.t("analytics.index.moved_label"))
  end
end
