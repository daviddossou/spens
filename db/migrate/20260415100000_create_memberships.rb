# frozen_string_literal: true

class CreateMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :memberships, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :space, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :memberships, [ :user_id, :space_id ], unique: true
  end
end
