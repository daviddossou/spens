# frozen_string_literal: true

require "rails_helper"

RSpec.describe Onboarding::LandingChoices do
  let(:user) { create(:user, onboarding_current_step: "onboarding_savings_projection") }
  let(:space) { user.spaces.first }

  before { space.update_columns(country: nil, financial_goals: []) }

  it "keeps only values the app knows" do
    choices = described_class.new(
      "country" => "bj", "currency" => "xof", "income" => "250 000", "savings_rate" => "15", "goals" => "save_regularly,not_a_goal",
      "accounts" => [ { "name" => " Cash ", "amount" => "1 200" }, { "name" => "", "amount" => "5" }, { "name" => "cash" } ]
    )

    expect(choices.to_h).to eq(
      "country" => "BJ", "currency" => "XOF", "income" => 250_000, "savings_rate" => 15, "goals" => %w[save_regularly],
      "accounts" => [ { "name" => "Cash", "amount" => "1200" } ]
    )
  end

  it "is empty for junk" do
    choices = described_class.new("country" => "ZZ", "currency" => "ABC", "income" => "0", "savings_rate" => "90",
                                  "goals" => "x", "accounts" => "nope")

    expect(choices.any?).to be(false)
    expect(described_class.new(nil).any?).to be(false)
  end

  it "fills the space and opens the accounts with their balance" do
    choices = described_class.new("country" => "FR", "currency" => "EUR", "income" => "2500", "savings_rate" => "20",
                                  "goals" => %w[pay_off_debt],
                                  "accounts" => [ { "name" => "Cash", "amount" => "150" }, { "name" => "Bank" } ])

    choices.apply_to(space, user: user)

    expect(space.reload).to have_attributes(country: "FR", currency: "EUR", monthly_income: 2500, savings_rate: 20,
                                            financial_goals: %w[pay_off_debt])
    expect(space.accounts.pluck(:name, :balance)).to contain_exactly([ "Cash", 150 ], [ "Bank", 0 ])
    expect(space.accounts.find_by(name: "Cash").transactions.count).to eq(1)
  end

  it "never overwrites what the space already answered" do
    space.update!(country: "CM", currency: "XAF", monthly_income: 100, savings_rate: 5, financial_goals: %w[track_spending])

    described_class.new("country" => "FR", "currency" => "EUR", "income" => "9", "savings_rate" => "30",
                        "goals" => %w[pay_off_debt]).apply_to(space, user: user)

    expect(space.reload).to have_attributes(country: "CM", currency: "XAF", monthly_income: 100, savings_rate: 5,
                                            financial_goals: %w[track_spending])
  end

  it "describes itself for analytics without amounts" do
    choices = described_class.new("country" => "BJ", "income" => "250000", "accounts" => [ { "name" => "Cash", "amount" => "9" } ])

    expect(choices.analytics_properties).to eq(landing_country: "BJ", landing_income_bracket: "200k-500k", landing_accounts: 1)
  end
end
