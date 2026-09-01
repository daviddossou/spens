# frozen_string_literal: true

require "rails_helper"

RSpec.describe AnalyticsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:account) { create(:account, user: user) }

  # Fixed mid-month noon: the controller reads dates in the user's time zone,
  # and a real midnight boundary would shift its "today" past the spec's.
  before do
    travel_to Time.zone.local(2026, 8, 18, 12)
    sign_in user, scope: :user
  end

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

  it "renders the biggest-day phrase as real HTML, never escaped tags" do
    spend(62_000)
    get analytics_path

    expect(response.body).to include("Your biggest day: <strong>")
    expect(response.body).not_to include("&lt;strong&gt;")
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

  describe "between you and others" do
    it "does not render the section without a debt" do
      spend(1_000)
      get analytics_path
      expect(response.body).not_to include(I18n.t("analytics.index.section_between"))
    end

    it "nets per person BEFORE aggregating — someone on both sides appears once" do
      create(:debt, user: user, name: "Mariam", direction: "lent", total_lent: 80_000, total_reimbursed: 0)
      create(:debt, user: user, name: "Gilchrist", direction: "lent", total_lent: 28_000, total_reimbursed: 0)
      create(:debt, :borrowed, user: user, name: "Gilchrist", direction: "borrowed", total_lent: 150_000, total_reimbursed: 0)

      get analytics_path

      expect(response.body).to include(I18n.t("analytics.index.settle_today"))
      expect(response.body).to include("Mariam")
      # Gilchrist once, at his 122 000 net on the owing side — never on both.
      expect(response.body.scan("Gilchrist").size).to eq(1)
      expect(response.body).to include("122,000")
    end
  end

  it "states the lent money as an addition under the hero, never in the total" do
    spend(10_000)
    debt_type = create(:transaction_type, space: space, kind: "debt_out", name: "Prêt X")
    create(:transaction, space: space, user: user, account: account,
                         transaction_type: debt_type, amount: -50_000, transaction_date: Date.current)

    get analytics_path
    expect(assigns(:spending).spent_total).to eq(10_000)
    expect(assigns(:spending).lent_total).to eq(50_000)
    expect(response.body).to include(I18n.t("analytics.index.lent_line", amount: "50,000\u00A0FCFA"))
  end
end
