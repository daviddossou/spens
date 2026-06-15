# frozen_string_literal: true

# A persistent trail of privileged admin actions — who did what, to whom, and when. Written
# whenever an admin impersonates a user, approves/rejects learned vocabulary, or grants/revokes
# admin. `admin_user` is always the real acting admin (the true admin, even mid-impersonation).
# `target` is an optional polymorphic-ish pointer (we store type + id loosely so we can log a
# user, a learned alias/keyword, etc. without a hard association).
class AdminAuditLog < ApplicationRecord
  ACTIONS = %w[
    impersonate_start impersonate_stop
    approve_alias reject_alias approve_keyword reject_keyword
    grant_admin revoke_admin
  ].freeze

  belongs_to :admin_user, class_name: "User"

  validates :action, inclusion: { in: ACTIONS }

  scope :recent, -> { order(created_at: :desc) }

  # Records one action. `target` may be any record (we keep its class name + id) or nil.
  def self.record_action(admin_user:, action:, target: nil, metadata: {})
    create!(
      admin_user: admin_user,
      action: action,
      target_type: target&.class&.name,
      target_id: target&.id,
      metadata: metadata
    )
  end

  # Best-effort rehydration of the target (it may have since been deleted).
  def target
    return nil if target_type.blank? || target_id.blank?

    target_type.constantize.find_by(id: target_id)
  rescue NameError
    nil
  end
end
