# frozen_string_literal: true

# == Schema Information
#
# Table name: quick_entry_attempts
#
#  id             :uuid             not null, primary key
#  ai_draft       :jsonb
#  ai_used        :boolean          default(FALSE), not null
#  locale         :string
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
require "rails_helper"

RSpec.describe QuickEntryAttempt do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  describe ".record" do
    it "logs a confident attempt linked to the created transaction" do
      transaction = create(:transaction, space: space)
      draft = QuickEntry::Draft.new(kind: "expense", amount: 2000, transaction_type_name: "Zem")

      attempt = described_class.record(
        space: space, user: user, text: "2000 zem", locale: :en, draft: draft, transaction: transaction
      )

      expect(attempt.source).to eq("rules")
      expect(attempt.created_transaction).to eq(transaction)
      expect(attempt.outcome).to eq("pending")
      expect(attempt.rules_draft).to include("kind" => "expense", "amount" => 2000)
    end

    it "logs a manual fallback when nothing was auto-created" do
      draft = QuickEntry::Draft.new(kind: "transfer", amount: 5000)

      attempt = described_class.record(
        space: space, user: user, text: "transfer 5000", locale: :en, draft: draft
      )

      expect(attempt.source).to eq("manual_fallback")
      expect(attempt.created_transaction).to be_nil
    end
  end
end
