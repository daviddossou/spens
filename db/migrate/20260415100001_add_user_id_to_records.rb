# frozen_string_literal: true

class AddUserIdToRecords < ActiveRecord::Migration[8.0]
  def change
    add_reference :transactions, :user, type: :uuid, foreign_key: true, null: true
    add_reference :debts, :user, type: :uuid, foreign_key: true, null: true
    add_reference :accounts, :user, type: :uuid, foreign_key: true, null: true
  end
end
