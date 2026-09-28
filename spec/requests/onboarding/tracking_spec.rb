# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Onboarding analytics", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user, onboarding_current_step: "onboarding_financial_goal") }
  let(:space) { user.spaces.first }
  let(:events) { [] }

  before do
    allow(Analytics).to receive(:track) { |_user, event, props = {}| events << [ event, props ] }
    allow(Analytics).to receive(:group_identify)
    sign_in user, scope: :user
  end

  def event(name)
    events.find { |recorded, _| recorded == name }&.last
  end

  it "reports a step as viewed" do
    get onboarding_financial_goals_path

    expect(event("onboarding_step_viewed")).to include(step: "financial_goal", first_space: true)
  end

  it "sends one event per chosen problem and writes the choice on the person" do
    patch onboarding_financial_goals_path, params: {
      onboarding_financial_goal_form: { financial_goals: %w[pay_off_debt save_regularly] },
      landing_goals: "pay_off_debt,not_a_goal"
    }

    chosen = events.select { |name, _| name == "onboarding_goal_chosen" }.map(&:last)
    expect(chosen).to contain_exactly(
      include(goal: "pay_off_debt", from_landing: true), include(goal: "save_regularly", from_landing: false)
    )
    expect(event("onboarding_step_completed")).to include(
      step: "financial_goal", goals_count: 2, goals_from_landing: %w[pay_off_debt], goals_changed_from_landing: true
    )
    expect(event("onboarding_step_completed")["$set"]).to include(
      "goal_pay_off_debt" => true, "goal_track_spending" => false, onboarding_step: "onboarding_profile_setup"
    )
  end

  it "reports a failed step with the fields in error" do
    patch onboarding_financial_goals_path, params: { onboarding_financial_goal_form: { financial_goals: [ "" ] } }

    expect(event("onboarding_step_failed")).to include(step: "financial_goal", errors: include("financial_goals"))
    expect(event("onboarding_step_completed")).to be_nil
  end

  it "reports the profile answers" do
    space.update!(onboarding_current_step: "onboarding_profile_setup")

    patch onboarding_profile_setups_path, params: {
      onboarding_profile_setup_form: { country: "BJ", currency: "XOF", income_frequency: "monthly", main_income_source: "salary" }
    }

    expect(event("onboarding_step_completed")).to include(
      step: "profile_setup", country: "BJ", currency: "XOF", income_frequency: "monthly", main_income_source: "salary"
    )
  end

  it "counts the day's expenses and accounts, and keeps account names private" do
    space.update!(onboarding_current_step: "onboarding_first_day", country: "BJ", currency: "XOF",
                  financial_goals: %w[track_spending])

    post transactions_path, params: { transaction: { kind: "expense", amount: "2000", transaction_type_name: "Riz",
                                                     account_name: I18n.t("account_templates.mobile_money") } }
    post transactions_path, params: { transaction: { kind: "expense", amount: "500", transaction_type_name: "Zem",
                                                     account_name: "Tontine de maman" } }
    patch onboarding_first_days_path
    accounts = space.accounts.order(:created_at)
    patch onboarding_balances_path, params: { balances: { balances: { accounts.first.id => "8 500", accounts.last.id => "12000" },
                                                          extra: [ { name: I18n.t("account_templates.bank"), amount: "50000" } ] } }

    completed = event("onboarding_completed")
    expect(completed).to include(expenses: 2, accounts: 3, extra_accounts: 1, financial_goals: %w[track_spending], country: "BJ")
    expect(completed.to_s).not_to include("Tontine")
  end

  it "does not describe the person from a second space" do
    # Switching space is only allowed from an onboarded one; pin it in the session first
    # (without a session choice the app falls back to an arbitrary space).
    space.update!(onboarding_current_step: "onboarding_completed", country: "BJ")
    post space_selection_path(space_id: space.id)
    second = create(:space, user: user, onboarding_current_step: "onboarding_financial_goal", created_at: 1.hour.from_now)
    post space_selection_path(space_id: second.id)
    expect(response).to redirect_to(dashboard_path)
    events.clear

    patch onboarding_financial_goals_path, params: { onboarding_financial_goal_form: { financial_goals: %w[track_spending] } }

    expect(event("onboarding_step_completed")).to include(first_space: false)
    expect(event("onboarding_step_completed")).not_to have_key("$set")
  end
end
