# == Schema Information
#
# Table name: users
#
#  id                      :uuid             not null, primary key
#  country                 :string           indexed
#  currency                :string           default("XOF"), indexed
#  current_sign_in_at      :datetime
#  current_sign_in_ip      :string
#  email                   :string           default(""), not null, indexed
#  encrypted_password      :string           default(""), not null
#  financial_goals         :jsonb
#  first_name              :string
#  income_frequency        :string
#  last_name               :string
#  last_sign_in_at         :datetime
#  last_sign_in_ip         :string
#  main_income_source      :string
#  onboarding_current_step :string           indexed
#  phone_number            :string
#  remember_created_at     :datetime
#  reset_password_sent_at  :datetime
#  reset_password_token    :string           indexed
#  sign_in_count           :integer          default(0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_users_on_country                  (country)
#  index_users_on_currency                 (currency)
#  index_users_on_email                    (email) UNIQUE
#  index_users_on_onboarding_current_step  (onboarding_current_step)
#  index_users_on_reset_password_token     (reset_password_token) UNIQUE
#
class User < ApplicationRecord
  ##
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  ##
  # Associations
  has_many :accounts, dependent: :destroy
  has_many :transaction_types, dependent: :destroy
  has_many :transactions, dependent: :destroy

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
  # Validations && Enums
  validates :password, length: { minimum: 6, maximum: 128 }, allow_blank: true
  validates :password, confirmation: true
  validates :first_name, :last_name, presence: true
  validates :phone_number, format: { with: /\A[\+]?[1-9]?[0-9]{7,15}\z/, message: "must be a valid phone number" }, allow_blank: true
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
  # Instances Methods
  def onboarding_completed?
    onboarding_current_step == "onboarding_completed"
  end

  private

    def requires_country?
      %w[onboarding_profile_setup onboarding_account_setup onboarding_completed].include?(onboarding_current_step)
    end
end
