# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           default(""), not null, indexed
#  encrypted_password     :string           default(""), not null
#  first_name             :string
#  last_name              :string
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  otp_code               :string
#  otp_sent_at            :datetime
#  phone_number           :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string           indexed
#  sign_in_count          :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
class User < ApplicationRecord
  ##
  # Devise modules
  devise :database_authenticatable, :trackable

  ##
  # Associations
  has_many :owned_spaces, class_name: "Space", dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :spaces, through: :memberships
  has_many :accounts, through: :spaces
  has_many :transaction_types, through: :spaces
  has_many :transactions, through: :spaces
  has_many :debts, through: :spaces
  has_many :invitations, foreign_key: :invited_by_id, dependent: :destroy

  ##
  # Constants
  OTP_VALIDITY = 10.minutes

  ##
  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: Devise.email_regexp }
  validates :first_name, :last_name, presence: true
  validates :phone_number, format: { with: /\A[\+]?[1-9]?[0-9]{7,15}\z/, message: "must be a valid phone number" }, allow_blank: true

  ##
  # Instance Methods
  def generate_otp!
    update!(
      otp_code: SecureRandom.random_number(10**6).to_s.rjust(6, "0"),
      otp_sent_at: Time.current
    )
  end

  def verify_otp(code)
    return false if otp_code.blank? || otp_sent_at.blank?
    return false if otp_expired?
    return false unless ActiveSupport::SecurityUtils.secure_compare(otp_code, code.to_s)

    clear_otp!
    true
  end

  def otp_expired?
    otp_sent_at.nil? || otp_sent_at < OTP_VALIDITY.ago
  end

  private

    def clear_otp!
      update!(otp_code: nil, otp_sent_at: nil)
    end
end
