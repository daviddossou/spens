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
  CURRENCIES = %w[XOF XAF EUR USD GBP CAD AUD JPY CHF CNY INR BRL].freeze
  INCOME_FREQUENCIES = %w[weekly biweekly monthly quarterly annually].freeze
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
  validates :currency, inclusion: { in: CURRENCIES }, presence: true
  validates :country, presence: true
  validates :income_frequency, inclusion: { in: INCOME_FREQUENCIES }, allow_blank: true

  enum :onboarding_current_step, {
    financial_goal: "financial_goal",
    personal_info: "personal_info",
    account_setup: "account_setup",
    completed: "completed"
  }
end
