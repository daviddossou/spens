# frozen_string_literal: true

# == Schema Information
#
# Table name: memberships
#
#  id                    :uuid             not null, primary key
#  accounts_nudge_at     :datetime
#  reminder_declined_at  :datetime
#  reminder_enabled      :boolean          default(FALSE), not null
#  reminder_hour         :integer          default(20), not null
#  reminder_last_sent_on :date
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  space_id              :uuid             not null, indexed, indexed => [user_id]
#  user_id               :uuid             not null, indexed, indexed => [space_id]
#
# Indexes
#
#  index_memberships_on_space_id              (space_id)
#  index_memberships_on_user_id               (user_id)
#  index_memberships_on_user_id_and_space_id  (user_id,space_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (space_id => spaces.id)
#  fk_rails_...  (user_id => users.id)
#
class Membership < ApplicationRecord
  ##
  # Associations
  belongs_to :user
  belongs_to :space

  ##
  # Constants
  DEFAULT_REMINDER_HOUR = 20
  DEFAULT_TIME_ZONE = "Africa/Porto-Novo"

  ##
  # Validations
  validates :user_id, uniqueness: { scope: :space_id }
  validates :reminder_hour, inclusion: { in: 0..23 }

  ##
  # Scopes
  scope :reminding, -> { where(reminder_enabled: true) }
  scope :nudge_due, -> { where(accounts_nudge_at: ..Time.current) }

  # The member's clock: their own zone, else the space's, else West Africa.
  def time_zone
    [ user.time_zone, space.time_zone ].filter_map { |zone| zone.presence && Time.find_zone(zone) }.first ||
      Time.find_zone(DEFAULT_TIME_ZONE)
  end

  def enable_reminder!(hour: nil)
    update!(reminder_enabled: true, reminder_hour: hour || reminder_hour, reminder_declined_at: nil)
  end

  def decline_reminder!
    update!(reminder_enabled: false, reminder_declined_at: Time.current)
  end

  # Whether this member already recorded something in the space today, on their clock.
  def noted_today?
    space.transactions.where(user: user, created_at: time_zone.now.all_day).exists?
  end
end
