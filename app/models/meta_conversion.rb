# frozen_string_literal: true

# One row per (user, event_name): the once-only ledger for Meta CAPI activation
# events (spens_first_account, spens_budget_complete, ...). The unique index is
# the guarantee; Meta::Activation.record inserts here before sending.
class MetaConversion < ApplicationRecord
  belongs_to :user

  validates :event_name, presence: true, uniqueness: { scope: :user_id }
end
