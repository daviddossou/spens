# == Schema Information
#
# Table name: accounts
#
#  id          :uuid             not null, primary key
#  archived_at :datetime         indexed
#  balance     :float            default(0.0), not null
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  space_id    :uuid             not null, indexed
#  user_id     :uuid             indexed
#
# Indexes
#
#  index_accounts_on_archived_at              (archived_at)
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
  rounds_money :balance

  ##
  # Associations
  belongs_to :space
  belongs_to :user, optional: true
  has_many :transactions, dependent: :destroy
  has_one :goal, dependent: :destroy

  ##
  # Validations
  validates :name, presence: true, length: { maximum: 100 }, uniqueness: { scope: :space_id, case_sensitive: false }
  validates :balance, presence: true, numericality: true

  ##
  # Scopes
  # An account is a savings account when it has a goal attached.
  scope :with_saving_goals, -> { joins(:goal) }
  # Archived accounts keep their history but drop out of the lists and pickers.
  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  ##
  # Instance Methods
  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def reactivate!
    update!(archived_at: nil)
  end

  ##
  # Class Methods
  class << self
    def templates(locale = I18n.locale)
      I18n.t("account_templates", locale: locale)
    end
  end
end
