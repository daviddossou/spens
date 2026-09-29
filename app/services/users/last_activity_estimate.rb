# frozen_string_literal: true

# Best guess of when a user last used the app, for rows that predate users.last_active_at.
# No session log exists: the answer is the newest of the Devise sign-in stamps (only refreshed
# by an OTP login), the e-mail confirmation (start of the second session), the last push usage
# and the newest write on anything the user authored or owns.
module Users
  module LastActivityEstimate
    module_function

    def call(user)
      owned_ids = user.owned_spaces.pluck(:id)
      [
        user.last_active_at, user.current_sign_in_at, user.last_sign_in_at, user.confirmed_at,
        user.push_subscriptions.maximum(:last_used_at),
        user.memberships.maximum(:updated_at),
        Space.where(id: owned_ids).maximum(:updated_at),
        authored(Account, user, owned_ids).maximum(:updated_at),
        authored(Transaction, user, owned_ids).maximum(:updated_at),
        authored(Debt, user, owned_ids).maximum(:updated_at),
        BudgetEntry.where(space_id: owned_ids).maximum(:updated_at),
        Goal.where(space_id: owned_ids).maximum(:updated_at)
      ].compact.max
    end

    # Rows without user_id (older data, or models without an author) belong to the space owner.
    def authored(model, user, owned_ids)
      model.where(user_id: user.id).or(model.where(user_id: nil, space_id: owned_ids))
    end
  end
end
