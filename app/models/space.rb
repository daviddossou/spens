# frozen_string_literal: true

# == Schema Information
#
# Table name: spaces
#
#  id                      :uuid             not null, primary key
#  country                 :string
#  currency                :string           default("XOF")
#  financial_goals         :jsonb
#  income_frequency        :string
#  main_income_source      :string
#  name                    :string           not null
#  onboarding_current_step :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  user_id                 :uuid             not null, indexed
#
# Indexes
#
#  index_spaces_on_user_id                 (user_id)
#  index_spaces_on_user_id_and_lower_name  (user_id, lower((name)::text)) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Space < ApplicationRecord
  ##
  # Associations
  belongs_to :user
  has_many :accounts, dependent: :destroy
  has_many :transaction_types, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :debts, dependent: :destroy

  ##
  # Constants
  CURRENCIES = CurrencyService.all_codes.freeze
  INCOME_FREQUENCIES = Onboarding::IncomeService::FREQUENCIES.freeze
  INCOME_SOURCES = Onboarding::IncomeService::SOURCES.freeze
  FINANCIAL_GOALS = %w[
    save_for_emergency
    pay_off_debt
    save_for_house
    save_for_retirement
    save_for_vacation
    build_wealth
    track_spending
    budget_better
  ].freeze

  ##
  # Validations & Enums
  validates :name, presence: true, length: { maximum: 100 },
                   uniqueness: { scope: :user_id, case_sensitive: false }
  validates :currency, inclusion: { in: CURRENCIES }, allow_nil: true
  validates :country, presence: true, if: :requires_country?
  validates :income_frequency, inclusion: { in: INCOME_FREQUENCIES }, allow_blank: true
  validates :main_income_source, inclusion: { in: INCOME_SOURCES }, allow_blank: true

  enum :onboarding_current_step, {
    onboarding_financial_goal: "onboarding_financial_goal",
    onboarding_profile_setup: "onboarding_profile_setup",
    onboarding_account_setup: "onboarding_account_setup",
    onboarding_completed: "onboarding_completed"
  }

  ##
  # Instance Methods
  def onboarding_completed?
    onboarding_current_step == "onboarding_completed"
  end

  private

  def requires_country?
    %w[onboarding_account_setup onboarding_completed].include?(onboarding_current_step)
  end
end
