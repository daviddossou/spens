# frozen_string_literal: true

# == Schema Information
#
# Table name: invitations
#
#  id            :uuid             not null, primary key
#  accepted_at   :datetime
#  email         :string           not null, indexed => [space_id]
#  token         :string           not null, indexed
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  invited_by_id :uuid             not null, indexed
#  space_id      :uuid             not null, indexed, indexed => [email]
#
# Indexes
#
#  index_invitations_on_invited_by_id       (invited_by_id)
#  index_invitations_on_space_id            (space_id)
#  index_invitations_on_space_id_and_email  (space_id,email) UNIQUE
#  index_invitations_on_token               (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (invited_by_id => users.id)
#  fk_rails_...  (space_id => spaces.id)
#
class Invitation < ApplicationRecord
  ##
  # Associations
  belongs_to :space
  belongs_to :invited_by, class_name: "User"

  ##
  # Token
  has_secure_token :token

  ##
  # Validations
  validates :email, presence: true,
                    format: { with: Devise.email_regexp }
  validates :email, uniqueness: { scope: :space_id, case_sensitive: false, message: :already_invited }
  validate :invitee_not_already_member, on: :create

  ##
  # Scopes
  scope :pending, -> { where(accepted_at: nil) }

  ##
  # Instance Methods
  def accepted?
    accepted_at.present?
  end

  def accept!(user)
    transaction do
      space.memberships.find_or_create_by!(user: user)
      update!(accepted_at: Time.current)
    end
  end

  private

  def invitee_not_already_member
    return if email.blank? || space.blank?

    existing_user = User.find_by("LOWER(email) = ?", email.downcase)
    return unless existing_user

    if space.memberships.exists?(user: existing_user)
      errors.add(:email, :already_member)
    end
  end
end
