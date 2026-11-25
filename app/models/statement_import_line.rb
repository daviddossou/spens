# frozen_string_literal: true

# == Schema Information
#
# Table name: statement_import_lines
#
#  id                      :uuid             not null, primary key
#  amount                  :decimal(15, 2)
#  balance                 :decimal(15, 2)
#  capture_index           :integer          not null
#  currency                :string
#  decision                :string           default("pending"), not null
#  extracted               :jsonb            not null
#  fee                     :decimal(15, 2)
#  final                   :jsonb
#  flags                   :jsonb            not null
#  kind                    :string
#  label                   :string
#  needs_review            :boolean          default(FALSE), not null
#  occurred_at             :datetime
#  occurred_on             :date
#  position                :integer          not null
#  reference               :string
#  status                  :string           not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :uuid             indexed
#  counterpart_account_id  :uuid             indexed
#  created_transaction_id  :uuid             indexed
#  debt_id                 :uuid             indexed
#  duplicate_of_id         :uuid             indexed
#  existing_transaction_id :uuid             indexed
#  statement_import_id     :uuid             not null, indexed
#
# Indexes
#
#  index_statement_import_lines_on_account_id               (account_id)
#  index_statement_import_lines_on_counterpart_account_id   (counterpart_account_id)
#  index_statement_import_lines_on_created_transaction_id   (created_transaction_id)
#  index_statement_import_lines_on_debt_id                  (debt_id)
#  index_statement_import_lines_on_duplicate_of_id          (duplicate_of_id)
#  index_statement_import_lines_on_existing_transaction_id  (existing_transaction_id)
#  index_statement_import_lines_on_statement_import_id      (statement_import_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => nullify
#  fk_rails_...  (counterpart_account_id => accounts.id) ON DELETE => nullify
#  fk_rails_...  (created_transaction_id => transactions.id) ON DELETE => nullify
#  fk_rails_...  (debt_id => debts.id) ON DELETE => nullify
#  fk_rails_...  (duplicate_of_id => statement_import_lines.id) ON DELETE => nullify
#  fk_rails_...  (existing_transaction_id => transactions.id) ON DELETE => nullify
#  fk_rails_...  (statement_import_id => statement_imports.id)
#
class StatementImportLine < ApplicationRecord
  STATUSES = %w[ok declined pending card_check not_transaction cut_off duplicate].freeze
  DECISIONS = %w[pending accepted skipped].freeze

  belongs_to :statement_import, inverse_of: :lines
  belongs_to :account, optional: true
  belongs_to :counterpart_account, class_name: "Account", optional: true
  belongs_to :debt, optional: true
  belongs_to :duplicate_of, class_name: "StatementImportLine", optional: true
  belongs_to :existing_transaction, class_name: "Transaction", optional: true
  belongs_to :created_transaction, class_name: "Transaction", optional: true

  validates :status, inclusion: { in: STATUSES }
  validates :decision, inclusion: { in: DECISIONS }

  scope :proposed, -> { where(status: "ok", duplicate_of_id: nil) }

  def proposed?
    status == "ok" && duplicate_of_id.nil?
  end
end
