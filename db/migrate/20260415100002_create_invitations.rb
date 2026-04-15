# frozen_string_literal: true

class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations, id: :uuid do |t|
      t.references :space, null: false, foreign_key: true, type: :uuid
      t.references :invited_by, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.string :email, null: false
      t.string :token, null: false
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :invitations, :token, unique: true
    add_index :invitations, [ :space_id, :email ], unique: true
  end
end
