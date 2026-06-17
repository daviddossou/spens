# == Schema Information
#
# Table name: quick_entry_attempts
#
#  id             :uuid             not null, primary key
#  ai_draft       :jsonb
#  ai_used        :boolean          default(FALSE), not null
#  corrections    :jsonb
#  locale         :string
#  mined_at       :datetime         indexed
#  outcome        :string           default("pending"), not null, indexed
#  rules_draft    :jsonb            not null
#  source         :string           not null
#  text           :text             not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  space_id       :uuid             not null, indexed
#  transaction_id :uuid             indexed
#  user_id        :uuid             not null, indexed
#
# Indexes
#
#  index_quick_entry_attempts_on_mined_at        (mined_at)
#  index_quick_entry_attempts_on_outcome         (outcome)
#  index_quick_entry_attempts_on_space_id        (space_id)
#  index_quick_entry_attempts_on_transaction_id  (transaction_id)
#  index_quick_entry_attempts_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (space_id => spaces.id)
#  fk_rails_...  (transaction_id => transactions.id) ON DELETE => nullify
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :quick_entry_attempt do
    association :user
    space { user.spaces.first || association(:space, user: user) }
    text { "2000 zem" }
    locale { "en" }
    rules_draft { { "kind" => "expense", "amount" => 2000 } }
    source { "rules" }
    outcome { "pending" }
  end
end
