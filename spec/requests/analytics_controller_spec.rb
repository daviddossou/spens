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

    it "shows the net first, both gross lists, and the two-sided net note" do
      create(:debt, user: user, name: "Mariam", direction: "lent", total_lent: 80_000, total_reimbursed: 0)
      create(:debt, user: user, name: "Gilchrist", direction: "lent", total_lent: 28_000, total_reimbursed: 0)
      create(:debt, :borrowed, user: user, name: "Gilchrist", direction: "borrowed", total_lent: 150_000, total_reimbursed: 0)

      get analytics_path

      expect(response.body).to include(I18n.t("analytics.index.settle_today"))
      expect(response.body).to include("Mariam")
      expect(response.body).to include(I18n.t("analytics.index.who_owes_you"))
      expect(response.body).to include(I18n.t("analytics.index.whom_you_owe"))
      # Gilchrist on both sides: gross on each list + an explicit net note (122 000).
      expect(response.body).to include(I18n.t("analytics.index.both_sides_you_owe", amount: "122,000"))
    end
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
