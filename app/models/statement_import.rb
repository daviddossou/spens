# frozen_string_literal: true

# == Schema Information
#
# Table name: statement_imports
#
#  id         :uuid             not null, primary key
#  error      :text
#  model      :string
#  reads      :jsonb            not null
#  saved_at   :datetime
#  source     :string
#  status     :string           default("reading"), not null, indexed
#  undone_at  :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :uuid             indexed
#  space_id   :uuid             not null, indexed
#  user_id    :uuid             not null, indexed
#
# Indexes
#
#  index_statement_imports_on_account_id  (account_id)
#  index_statement_imports_on_space_id    (space_id)
#  index_statement_imports_on_status      (status)
#  index_statement_imports_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => nullify
#  fk_rails_...  (space_id => spaces.id)
#  fk_rails_...  (user_id => users.id)
#
class StatementImport < ApplicationRecord
  STATUSES = %w[reading ready failed saved undone].freeze
  MAX_CAPTURES = 5
  CONTENT_TYPES = %w[image/jpeg image/png image/webp application/pdf].freeze
  MAX_BYTES = 10.megabytes
  # Stated in the privacy policy: change both together.
  CAPTURE_RETENTION = 90.days

  belongs_to :space
  belongs_to :user
  belongs_to :account, optional: true
  has_many :lines, -> { order(:position) }, class_name: "StatementImportLine", dependent: :destroy, inverse_of: :statement_import
  has_many :transactions, dependent: :nullify
  has_many_attached :captures

  validates :status, inclusion: { in: STATUSES }
  validate :captures_are_readable, on: :create

  STATUSES.each { |s| define_method(:"#{s}?") { status == s } }

  private

  def captures_are_readable
    errors.add(:captures, :blank) if captures.empty?
    errors.add(:captures, :too_many, count: MAX_CAPTURES) if captures.size > MAX_CAPTURES
    captures.each do |capture|
      errors.add(:captures, :invalid_type) unless CONTENT_TYPES.include?(capture.content_type)
      errors.add(:captures, :too_big) if capture.byte_size.to_i > MAX_BYTES
    end
  end
end
