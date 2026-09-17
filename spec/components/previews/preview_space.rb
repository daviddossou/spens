# frozen_string_literal: true

# Previews run with no database rows and outside a signed-in request. This
# lends a component the app's real view helpers (money, routes, i18n) with a
# stubbed current space and user, and unsaved records to render.
module PreviewSpace
  def preview_space
    @preview_space ||= Space.new(id: SecureRandom.uuid, name: "Personal", currency: "XOF", country: "BJ",
                                 user: preview_user)
  end

  def preview_user
    @preview_user ||= User.new(id: SecureRandom.uuid, email: "awa@example.com", first_name: "Awa", last_name: "Diop")
  end

  def preview_helpers
    @preview_helpers ||= begin
      controller = ApplicationController.new
      controller.request = ActionDispatch::TestRequest.create
      space = preview_space
      user = preview_user
      controller.view_context.tap do |context|
        context.define_singleton_method(:current_space) { space }
        context.define_singleton_method(:current_user) { user }
      end
    end
  end

  # Routes the component (and everything it renders) through the stubbed helpers.
  def with_helpers(component)
    component.instance_variable_set(:@__vc_helpers, preview_helpers)
    component.__vc_original_view_context = preview_helpers
    component
  end

  def build_account(name: "Wave", balance: 145_000, goal: nil, archived_at: nil)
    Account.new(id: SecureRandom.uuid, name: name, balance: balance, space: preview_space,
                archived_at: archived_at, set_aside: goal.present?).tap do |account|
      account.goal = goal if goal
    end
  end

  def build_goal(account, name: "Trip to Dakar", target_amount: 500_000, deadline: Date.current >> 9, created_at: 3.months.ago)
    Goal.new(id: SecureRandom.uuid, name: name, target_amount: target_amount, deadline: deadline,
             account: account, space: preview_space, created_at: created_at).tap { |goal| account.goal = goal }
  end

  def build_type(name, kind)
    TransactionType.new(id: SecureRandom.uuid, name: name, kind: kind, space: preview_space)
  end

  def build_transaction(kind:, category:, amount:, account: build_account, date: Date.current, note: nil, label: nil, debt: nil)
    Transaction.new(id: SecureRandom.uuid, amount: amount, transaction_date: date, note: note, label: label,
                    transaction_type: build_type(category, kind), account: account, debt: debt,
                    space: preview_space, created_at: Time.current, updated_at: Time.current)
  end
end
