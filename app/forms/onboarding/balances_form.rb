# frozen_string_literal: true

# Step 3, "your money": what each account holds NOW, after the day's expenses. The opening
# balance is written as a "Solde de départ" movement of (entered - current balance), so the
# expenses already noted keep pointing at the right morning figure. Extra places the user
# adds on this screen are created with their balance as opening movement.
class Onboarding::BalancesForm < BaseForm
  NEXT_STEP = "onboarding_summary"
  INITIAL_BALANCE_KIND = "initial_balance"
  # Places offered under the list; the rest is one tap further, in the picker.
  CHIPS = 4

  attr_reader :space, :user, :accounts, :balances, :extra

  def initialize(space, user:, payload: {})
    @space = space
    @user = user
    @accounts = space.accounts.active.order(:created_at).to_a
    @balances = (payload[:balances] || {}).to_h.to_h { |id, value| [ id.to_s, AmountInput.normalize(value.to_s) ] }
    @extra = extra_rows(payload[:extra])
  end

  validate :every_account_has_a_balance

  def balance_for(account)
    balances[account.id.to_s]
  end

  def submit
    return false if invalid?

    ActiveRecord::Base.transaction do
      accounts.each { |account| record_opening_balance(account, balance_for(account).to_d) }
      extra.each { |row| create_extra_account(row) }
      space.update!(onboarding_current_step: NEXT_STEP)
    end

    true
  rescue StandardError => e
    handle_submit_error(e)
  end

  private

  # A blank extra row is a chip tapped then left alone: dropped, never an error.
  def extra_rows(rows)
    rows = rows.is_a?(Hash) ? rows.values : Array(rows)
    rows.filter_map do |row|
      name = row[:name].to_s.strip
      amount = AmountInput.normalize(row[:amount].to_s)
      next if name.blank? || amount.blank?

      { name: name, amount: amount }
    end
  end

  def every_account_has_a_balance
    accounts.each do |account|
      value = balance_for(account)
      next if value.present? && value.match?(/\A\d+([.,]\d+)?\z/)

      errors.add(:base, I18n.t("onboarding.balances.errors.missing", account: account.name))
    end
  end

  def record_opening_balance(account, entered)
    difference = entered - account.balance.to_d
    return if difference.zero?

    name = I18n.t("transactions.initial_balance.type_name")
    type = FindOrCreateTransactionTypeService.new(space, name, INITIAL_BALANCE_KIND).call
    CreateTransactionService.new(space: space, user: user, account: account, transaction_type: type,
                                 amount: difference, transaction_date: Date.current, description: name).call
  end

  def create_extra_account(row)
    form = AccountForm.new(space, account_name: row[:name], current_balance: row[:amount])
    form.user = user
    raise UserFacingError, form.errors.full_messages.first unless form.submit
  end
end
