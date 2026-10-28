# == Schema Information
#
# Table name: cohorts
#
#  id                 :uuid             not null, primary key
#  active             :boolean          default(FALSE), not null
#  campaign           :string           not null, indexed
#  whatsapp_group_url :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_cohorts_on_campaign  (campaign) UNIQUE
#
# One run of the WhatsApp training. Its campaign name travels as utm_campaign on
# every /c/<code> redirect, so the next cohort reuses the same codes under a new
# name. Exactly one is active at a time.
class Cohort < ApplicationRecord
  validates :campaign, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }

  def self.current
    active.order(updated_at: :desc).first
  end

  # Idempotent: creates the cohort if needed, makes it the only active one, and
  # keeps the group URL unless a new one is given.
  def self.activate!(campaign, group_url: nil)
    transaction do
      where.not(campaign: campaign).update_all(active: false)
      cohort = find_or_initialize_by(campaign: campaign)
      cohort.active = true
      cohort.whatsapp_group_url = group_url if group_url.present?
      cohort.save!
      cohort
    end
  end
end
