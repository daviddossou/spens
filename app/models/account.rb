# == Schema Information
#
# Table name: accounts
#
#  id                    :uuid             not null, primary key
#  balance               :float            default(0.0), not null
#  name                  :string           not null
#  savings_goal          :boolean          default(FALSE), not null
#  savings_goal_amount   :float
#  savings_goal_deadline :date
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  space_id              :uuid             not null, indexed
#  user_id               :uuid             indexed
#
# Indexes
#
#  index_accounts_on_lower_name_and_space_id  (lower((name)::text), space_id) UNIQUE
#  index_accounts_on_space_id                 (space_id)
#  index_accounts_on_user_id                  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (space_id => spaces.id)
#  fk_rails_...  (user_id => users.id)
#
class Account < ApplicationRecord
  rounds_money :balance, :savings_goal_amount

  ##
  # Associations
  belongs_to :space
  belongs_to :user, optional: true
  has_many :transactions, dependent: :destroy

  ##
  # Validations
  validates :name, presence: true, length: { maximum: 100 }, uniqueness: { scope: :space_id, case_sensitive: false }
  # The target amount is optional (nil until the user sets one); the savings_goal
  # boolean is what marks the account as a goal.
  validates :savings_goal_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :balance, presence: true, numericality: true

  ##
  # Scopes
  scope :with_saving_goals, -> { where(savings_goal: true) }

  ##
  # Class Methods
  class << self
    def templates(locale = I18n.locale)
      I18n.t("account_templates", locale: locale)
    end
  end
end
