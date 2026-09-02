# frozen_string_literal: true

class BudgetItemForm < BaseForm
  ##
  # Attributes
  attr_accessor :space, :budget_item, :user

  attribute :kind, :string, default: "expense"
  attribute :transaction_type_name, :string
  attribute :from_account_name, :string
  attribute :to_account_name, :string
  attribute :contact_name, :string
  attribute :amount, :decimal
  attribute :frequency, :string, default: "monthly"
  attribute :rollover, :boolean, default: false
  attribute :essential, :boolean, default: true
  attribute :starts_on, :date, default: -> { Date.current.beginning_of_month }
  attribute :ends_on, :date
  # The month the edit was made from — a rule change takes effect here, freezing
  # earlier months. Not persisted; only steers rematerialization.
  attribute :effective_month, :date

  ##
  # Validations
  validates :kind, presence: true, inclusion: { in: BudgetItem::KINDS }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :frequency, presence: true, inclusion: { in: BudgetItem::FREQUENCIES }
  validates :starts_on, presence: true
  validate :ends_on_not_before_starts_on

  validates :transaction_type_name, presence: true, if: :category_kind?
  # The source is optional, as it is on the model: « mets X de côté » is a
  # complete instruction, and it is the shape a goal's own line already takes.
  validates :to_account_name, presence: true, if: :transfer_kind?
  validate :different_accounts_for_transfer, if: :transfer_kind?
  validates :contact_name, presence: true, if: :debt_kind?

  class << self
    def model_name
      ActiveModel::Name.new(self, nil, "BudgetItem")
    end
  end

  def initialize(space, payload = {})
    @space = space
    @budget_item = payload.delete(:budget_item)

    if editing?
      payload[:kind] ||= @budget_item.kind
      payload[:transaction_type_name] ||= @budget_item.transaction_type&.name
      payload[:from_account_name] ||= @budget_item.from_account&.name
      payload[:to_account_name] ||= @budget_item.to_account&.name
      payload[:contact_name] ||= @budget_item.debt&.name
      payload[:amount] ||= @budget_item.amount
      payload[:frequency] ||= @budget_item.frequency
      payload[:rollover] = @budget_item.rollover if payload[:rollover].nil?
      payload[:essential] = @budget_item.essential if payload[:essential].nil?
      payload[:starts_on] ||= @budget_item.starts_on
      payload[:ends_on] ||= @budget_item.ends_on
    end

    super(
      kind: payload[:kind].presence || "expense",
      transaction_type_name: payload[:transaction_type_name],
      from_account_name: payload[:from_account_name],
      to_account_name: payload[:to_account_name],
      contact_name: payload[:contact_name],
      amount: payload[:amount],
      frequency: payload[:frequency] || "monthly",
      rollover: payload[:rollover] || false,
      essential: payload.fetch(:essential, true),
      starts_on: payload[:starts_on] || Date.current.beginning_of_month,
      ends_on: payload[:ends_on],
      effective_month: payload[:effective_month]
    )
  end

  def editing?
    @budget_item&.persisted? || false
  end

  def persisted?
    editing?
  end

  def to_key
    editing? ? [ @budget_item.id ] : nil
  end

  def to_model
    self
  end

  def category_kind?
    BudgetItem::CATEGORY_KINDS.include?(kind)
  end

  def transfer_kind?
    kind == "transfer"
  end

  def debt_kind?
    BudgetItem::DEBT_KINDS.include?(kind)
  end

  def submit
    return false if invalid?

    ActiveRecord::Base.transaction do
      attrs = resolved_references.merge(
        kind: kind, amount: amount, frequency: frequency, starts_on: starts_on.beginning_of_month,
        ends_on: ends_on, rollover: (kind == "expense" && rollover), essential: essential
      )

      if editing?
        @budget_item.update!(attrs)
      else
        existing = existing_active_item(attrs)
        if existing && starts_on.beginning_of_month < existing.starts_on
          # The category already has a rule, but it starts later than the month
          # being added — so this isn't a duplicate, it's extending the same rule
          # backward to cover the earlier month. Move its start (and adopt the
          # freshly entered values) rather than blocking.
          existing.update!(attrs)
          @budget_item = existing
        elsif existing
          add_custom_error(duplicate_error_field, I18n.t("budgets.form.already_budgeted"))
          raise ActiveRecord::Rollback
        else
          @budget_item = space.budget_items.create!(attrs)
        end
      end

      rematerialize_entries
    end

    errors.empty?
  rescue ActiveRecord::RecordInvalid => e
    promote_errors(e.record.errors)
    false
  rescue StandardError => e
    Rails.logger.error "BudgetItemForm submit error: #{e.message}\n#{e.backtrace.join("\n")}"
    add_custom_error(:base, e.message)
    false
  end

  ##
  # View data
  def transaction_type_options
    TransactionTypeSuggestionsService.new(space, kind).options
  end

  def default_transaction_type_options
    TransactionTypeSuggestionsService.new(space, kind).default_options
  end

  # Categories a live budget line already covers: the layer groups on them, so a
  # duplicate is visible before it is created (Tour 32b-3).
  def planned_type_names
    space.budget_items.active.where(kind: kind)
         .joins(:transaction_type).pluck("transaction_types.name")
  end

  def account_suggestions
    AccountSuggestionsService.new(space).all_with_balances
  end

  def default_account_suggestions
    AccountSuggestionsService.new(space).defaults_with_balances
  end

  def debt_person_suggestions
    space.debts.ongoing.order(updated_at: :desc).pluck(:name).uniq
  end

  # Map of lowercased person name => [budget kinds], so picking an existing
  # person preselects the direction client-side (lent => they pay me).
  def debt_kinds_by_name
    space.debts.ongoing.each_with_object({}) do |debt, acc|
      key = debt.name.to_s.strip.downcase
      kind = debt.direction == "lent" ? "debt_in" : "debt_out"
      (acc[key] ||= []) << kind
      acc[key].uniq!
    end
  end

  # Per-person ongoing balance and who owes whom, so the debt branch can state
  # the current state ("You owe X") and auto-derive when the debt clears.
  def debt_summaries_by_name
    space.debts.ongoing.each_with_object({}) do |debt, acc|
      balance = debt.remaining_balance.to_f
      next unless balance.positive?

      key = debt.name.to_s.strip.downcase
      acc[key] = { balance: balance, direction: debt.direction } if !acc[key] || balance > acc[key][:balance]
    end
  end

  def frequency_options
    BudgetItem::FREQUENCIES.map { |f| [ I18n.t("budgets.frequencies.#{f}"), f ] }
  end

  def debt_direction_options
    [ [ I18n.t("budgets.form.debt_in"), "debt_in" ], [ I18n.t("budgets.form.debt_out"), "debt_out" ] ]
  end

  private

  def resolved_references
    case kind
    when "transfer"
      {
        transaction_type: nil, debt: nil,
        from_account: from_account_name.presence && FindOrCreateAccountService.new(space, from_account_name).call,
        to_account: FindOrCreateAccountService.new(space, to_account_name).call
      }
    when *BudgetItem::DEBT_KINDS
      # debt_in: they pay me back money I lent; debt_out: I repay money I borrowed.
      direction = kind == "debt_in" ? "lent" : "borrowed"
      {
        transaction_type: nil, from_account: nil, to_account: nil,
        debt: FindOrCreateDebtService.new(space, contact_name, direction, user).call
      }
    else
      {
        from_account: nil, to_account: nil, debt: nil,
        transaction_type: FindOrCreateTransactionTypeService.new(space, transaction_type_name, kind).call
      }
    end
  end

  # The active rule (if any) this line would collide with — one per category /
  # transfer pair / debt, by the same uniqueness the model enforces.
  def existing_active_item(attrs)
    scope = space.budget_items.active
    scope = scope.where.not(id: @budget_item.id) if editing?

    case kind
    when "transfer"
      scope.find_by(from_account: attrs[:from_account], to_account: attrs[:to_account])
    when *BudgetItem::DEBT_KINDS
      scope.find_by(debt: attrs[:debt], kind: kind)
    else
      scope.find_by(transaction_type: attrs[:transaction_type])
    end
  end

  def duplicate_error_field
    case kind
    when "transfer" then :to_account_name
    when *BudgetItem::DEBT_KINDS then :contact_name
    else :transaction_type_name
    end
  end

  def different_accounts_for_transfer
    return unless from_account_name.present? && to_account_name.present? &&
                  from_account_name.strip.downcase == to_account_name.strip.downcase

    errors.add(:to_account_name, I18n.t("errors.messages.different_account"))
  end

  def ends_on_not_before_starts_on
    return if ends_on.blank? || starts_on.blank? || ends_on >= starts_on

    errors.add(:ends_on, I18n.t("budgets.form.ends_on_before_starts_on"))
  end

  def rematerialize_entries
    Budgets::RematerializeItem.call(@budget_item, from_month: effective_month)
  end
end
