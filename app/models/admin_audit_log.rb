# frozen_string_literal: true

# == Schema Information
#
# Table name: admin_audit_logs
#
#  id            :uuid             not null, primary key
#  action        :string           not null, indexed
#  metadata      :jsonb            not null
#  target_type   :string           indexed => [target_id]
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  admin_user_id :uuid             not null, indexed
#  target_id     :uuid             indexed => [target_type]
#
# Indexes
#
#  index_admin_audit_logs_on_action                     (action)
#  index_admin_audit_logs_on_admin_user_id              (admin_user_id)
#  index_admin_audit_logs_on_target_type_and_target_id  (target_type,target_id)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => users.id)
#
class AdminAuditLog < ApplicationRecord
  ACTIONS = %w[
    impersonate_start impersonate_stop
    approve_alias reject_alias restore_alias create_alias reassign_alias
    approve_keyword reject_keyword restore_keyword
    teach_correction dismiss_correction
    create_taxonomy_node update_taxonomy_node activate_taxonomy_node
    deactivate_taxonomy_node destroy_taxonomy_node
    grant_admin revoke_admin
  ].freeze

  # UUID primary key → order by time, not the random id, so .first/.last/.recent are chronological.
  self.implicit_order_column = "created_at"

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
