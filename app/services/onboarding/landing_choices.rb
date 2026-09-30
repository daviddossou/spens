# frozen_string_literal: true

# The landing page's answers, sanitized for the session and applied to a fresh space:
# country and currency, the calculator's income and savings rate, the diagnostic's
# financial goals, the accounts typed in the "gather your money" block (created with
# their balance as opening movement).
class Onboarding::LandingChoices
  MAX_ACCOUNTS = 8
  NAME_LENGTH = 100

  attr_reader :country, :currency, :income, :savings_rate, :goals, :accounts

  def self.from_params(params)
    raw = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
    new(raw)
  end

  def initialize(raw)
    raw = (raw || {}).with_indifferent_access
    @country = ISO3166::Country[raw[:country].to_s.upcase]&.alpha2
    @currency = raw[:currency].to_s.upcase.presence_in(Space::CURRENCIES)
    @income = raw[:income].to_s.gsub(/\D/, "").to_i.then { |value| value if value.positive? }
    @savings_rate = raw[:savings_rate].to_s.to_i.presence_in(Onboarding::SavingsProjectionForm::RATE_RANGE)
    @goals = Array(raw[:goals].is_a?(String) ? raw[:goals].split(",") : raw[:goals]).map(&:to_s) & Space::FINANCIAL_GOALS
    @accounts = sanitize_accounts(raw[:accounts])
  end

  def any?
    country.present? || currency.present? || income.present? || savings_rate.present? || goals.any? || accounts.any?
  end

  def to_h
    { "country" => country, "currency" => currency, "income" => income, "savings_rate" => savings_rate,
      "goals" => goals.presence, "accounts" => accounts.presence }.compact
  end

  # Only fills what the space has not answered; a failed account is skipped, not fatal.
  def apply_to(space, user:)
    return unless any?

    if space.country.blank? && country
      space.country = country
      space.currency = currency if currency
    end
    space.monthly_income ||= income
    space.savings_rate ||= savings_rate
    space.financial_goals = goals if goals.any? && Array(space.financial_goals).empty?
    space.save!

    accounts.each do |account|
      form = AccountForm.new(space, account_name: account["name"], current_balance: account["amount"])
      form.user = user
      form.submit
    end
  end

  # For the sign-up event: what came from the landing, without amounts.
  def analytics_properties
    { landing_country: country, landing_currency: currency, landing_goals: goals.presence,
      landing_income_bracket: Analytics.amount_bracket(income), landing_savings_rate: savings_rate,
      landing_accounts: accounts.size }.compact
  end

  private

  def sanitize_accounts(rows)
    rows = rows.is_a?(Hash) ? rows.values : Array(rows)
    rows.filter_map do |row|
      next unless row.respond_to?(:[])

      name = row["name"].to_s.strip.first(NAME_LENGTH)
      amount = row["amount"].to_s.gsub(/[^\d.]/, "")
      next if name.blank?

      { "name" => name, "amount" => amount.present? && amount.to_d >= 0 ? amount : nil }.compact
    end.uniq { |row| row["name"].downcase }.first(MAX_ACCOUNTS)
  end
end
