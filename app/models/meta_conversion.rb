# frozen_string_literal: true

# == Schema Information
#
# Table name: meta_conversions
#
#  id         :uuid             not null, primary key
#  event_name :string           not null, indexed => [user_id]
#  created_at :datetime         not null
#  event_id   :uuid             not null
#  user_id    :uuid             not null, indexed, indexed => [event_name]
#
# Indexes
#
#  index_meta_conversions_on_user_id                 (user_id)
#  index_meta_conversions_on_user_id_and_event_name  (user_id,event_name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
# One row per (user, event_name): the once-only ledger for Meta CAPI activation
# events (spens_first_account, spens_budget_complete, ...). The unique index is
# the guarantee; Meta::Activation.record inserts here before sending.
class MetaConversion < ApplicationRecord
  belongs_to :user

  validates :event_name, presence: true, uniqueness: { scope: :user_id }
end
