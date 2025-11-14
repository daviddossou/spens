# == Schema Information
#
# Table name: accounts
#
#  id          :uuid             not null, primary key
#  balance     :float            default(0.0), not null
#  name        :string           not null
#  saving_goal :float            default(0.0)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :uuid             not null, indexed
#
# Indexes
#
#  index_accounts_on_lower_name_and_user_id  (lower((name)::text), user_id) UNIQUE
#  index_accounts_on_user_id                 (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Account < ApplicationRecord
  ##
  # Associations
  belongs_to :user
  has_many :transactions, dependent: :destroy

  ##
  # Validations
  validates :name, presence: true, length: { maximum: 100 }, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :saving_goal, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :balance, presence: true, numericality: true

  ##
  # Scopes
  scope :with_saving_goals, -> { where.not(saving_goal: 0) }

  ##
  # Class Methods
  class << self
    def templates(locale = I18n.locale)
      I18n.t("account_templates", locale: locale)
    end
  end
end
