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
#  locale                  :string
#  main_income_source      :string
#  monthly_savings_goal    :decimal(15, 2)
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
  has_many :memberships, dependent: :destroy
  has_many :members, through: :memberships, source: :user
  has_many :invitations, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :transaction_types, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :debts, dependent: :destroy
  has_many :budget_items, dependent: :destroy
  has_many :budget_entries, dependent: :destroy
  # The space's own learned vocabulary (personal tier — see Learnable)
  has_many :learned_aliases, dependent: :delete_all
  has_many :learned_keywords, dependent: :delete_all

  ##
  # Callbacks
  after_create :create_creator_membership

  private

  def create_creator_membership
    memberships.create!(user: user)
  end

  public

  ##
  # Constants
  CURRENCIES = CurrencyService.all_codes.freeze
  LOCALES = I18n.available_locales.map(&:to_s).freeze
  INCOME_FREQUENCIES = Onboarding::IncomeService::FREQUENCIES.freeze
  INCOME_SOURCES = Onboarding::IncomeService::SOURCES.freeze
  FINANCIAL_GOALS = %w[
    save_regularly
    cut_wasteful_spending
    track_spending
    track_all_accounts
    pay_off_debt
    track_repayments
  ].freeze

  ##
  # Validations & Enums
  validates :name, presence: true, length: { maximum: 100 },
                   uniqueness: { scope: :user_id, case_sensitive: false }
  validates :currency, inclusion: { in: CURRENCIES }, allow_nil: true
  validates :locale, inclusion: { in: LOCALES }, allow_nil: true
  validates :country, presence: true, if: :requires_country?
  validates :income_frequency, inclusion: { in: INCOME_FREQUENCIES }, allow_blank: true
  validates :main_income_source, inclusion: { in: INCOME_SOURCES }, allow_blank: true
  validates :monthly_savings_goal, numericality: { greater_than: 0 }, allow_nil: true

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
