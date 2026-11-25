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
  # draft: captures are being chosen; nothing is read until the user asks.
  STATUSES = %w[draft reading ready failed saved undone].freeze
  # Slots per import: an image takes one, a PDF one per page.
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

  attribute :status, default: "draft"

  validates :status, inclusion: { in: STATUSES }
  validate :captures_are_readable

  STATUSES.each { |s| define_method(:"#{s}?") { status == s } }

  def self.available_to?(user)
    user.can_use_statement_import? && StatementImports::Reader.enabled?
  end

  # An upload worth keeping: checked before attaching, so a bad file never lands on the import.
  def self.acceptable?(file)
    CONTENT_TYPES.include?(Marcel::MimeType.for(file, name: file.original_filename, declared_type: file.content_type)) &&
      file.size <= MAX_BYTES
  end

  def slots_used
    captures.sum { |capture| capture.blob.metadata.fetch("pages", 1).to_i }
  end

  def room_left
    MAX_CAPTURES - slots_used
  end

  def full?
    room_left <= 0
  end

  # Starts the reading: the user has chosen the captures and the account.
  def analyze!(account)
    return false unless draft? && captures.any? && account

    update!(account: account, status: "reading", reads: [], error: nil)
    StatementImports::ReadJob.perform_later(id)
    true
  end

  private

  def captures_are_readable
    errors.add(:captures, :blank) if new_record? && captures.empty?
    errors.add(:captures, :too_many, count: MAX_CAPTURES) if slots_used > MAX_CAPTURES
    captures.each do |capture|
      errors.add(:captures, :invalid_type) unless CONTENT_TYPES.include?(capture.content_type)
      errors.add(:captures, :too_big) if capture.byte_size.to_i > MAX_BYTES
    end
  end
end
