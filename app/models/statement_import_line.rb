# frozen_string_literal: true

# == Schema Information
#
# Table name: statement_import_lines
#
#  id                      :uuid             not null, primary key
#  amount                  :decimal(15, 2)
#  balance                 :decimal(15, 2)
#  capture_index           :integer          not null
#  categorization          :jsonb
#  category_source         :string
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
#  transaction_type_name   :string
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

  CATEGORY_KINDS = %w[expense income].freeze
  OUT_KINDS = %w[expense debt_out].freeze
  # Why a line is shown under "À vérifier", most important first.
  REVIEW_FLAGS = %w[already_in_spens foreign_currency own_name unbacked_transfer unbacked_debt debt_hint
                    unpaired_duplicate].freeze
  FORM_FIELDS = %w[kind account_name from_account_name to_account_name fee_amount transaction_date
                   transaction_type_name label contact_name direction].freeze

  def proposed?
    status == "ok" && duplicate_of_id.nil?
  end

  # Ticked in the review list: saved by "Enregistrer N transactions".
  def included?
    decision == "pending"
  end

  def category_kind?
    CATEGORY_KINDS.include?(kind)
  end

  def money_out?
    amount.to_d.negative?
  end

  # The first reason this line needs a look, or nil when it can go as it is.
  def review_reason
    return nil unless proposed?

    (REVIEW_FLAGS & flags).first ||
      ("no_category" if category_kind? && transaction_type_name.blank?) ||
      ("uncertain_category" if category_kind? && !%w[rules user].include?(category_source)) ||
      ("needs_review" if needs_review)
  end

  # Why a read line is set aside: its status, or how it duplicates another line.
  def ignored_reason
    return nil if proposed?
    return status unless %w[ok duplicate].include?(status)

    (%w[fee_row same_event overlap same_reference] & flags).first || "duplicate"
  end

  # A set-aside line the user can bring back into the list.
  def addable?
    !proposed? && amount.present? && !amount.zero? && !flags.include?("fee_row")
  end

  def restore!
    update!(status: "ok", duplicate_of: nil, decision: "pending")
  end

  # What saving this line sends to TransactionForm: the user's own edit when there is one.
  def payload
    base = final.presence || generated_payload
    base.merge("transaction_type_name" => transaction_type_name.presence || base["transaction_type_name"]).compact_blank
  end

  # The user edited the line in the transaction form (39c): keep their version, and mirror it on
  # the columns the list shows.
  def apply_form!(form)
    out = form.transfer? ? form.from_account_name.to_s.casecmp?(account&.name.to_s) : OUT_KINDS.include?(form.kind)
    self.final = form.attributes.slice(*FORM_FIELDS).transform_values { _1.is_a?(Date) ? _1.iso8601 : _1&.to_s }
                     .merge("amount" => form.amount.to_s, "debt_id" => form.debt_id).compact_blank
    self.kind = form.kind
    self.amount = out ? -form.amount : form.amount
    self.fee = form.fee_amount
    self.occurred_on = form.transaction_date
    self.label = form.label.presence || label
    self.transaction_type_name = form.transaction_type_name
    self.category_source = "user"
    self.currency = statement_import.space.currency
    self.flags = flags - %w[foreign_currency]
    self.needs_review = false
    self.decision = "pending"
    save!
  end

  private

  def generated_payload
    base = { "kind" => kind, "amount" => amount.abs.to_s, "fee_amount" => fee&.to_s,
             "transaction_date" => (occurred_on || Date.current).iso8601, "label" => label,
             "account_name" => account&.name, "debt_id" => debt_id }
    return base unless kind == "transfer"

    other = counterpart_account&.name
    ends = money_out? ? { "from_account_name" => account&.name, "to_account_name" => other } : { "from_account_name" => other, "to_account_name" => account&.name }
    base.merge(ends)
  end
end
