# frozen_string_literal: true

class CreateAdminAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_audit_logs, id: :uuid do |t|
      t.references :admin_user, null: false, type: :uuid, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :target_type
      t.uuid :target_id
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :admin_audit_logs, :action
    add_index :admin_audit_logs, [ :target_type, :target_id ]
  end
end
