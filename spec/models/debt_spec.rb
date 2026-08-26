# frozen_string_literal: true

# == Schema Information
#
# Table name: debts
#
#  id               :uuid             not null, primary key
#  deadline         :date
#  direction        :string           default("lent"), not null
#  name             :string           not null
#  note             :text
#  status           :string           default("ongoing"), not null, indexed
#  total_lent       :float            default(0.0), not null
#  total_reimbursed :float            default(0.0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  space_id         :uuid             not null, indexed
#  user_id          :uuid             indexed
#
# Indexes
#
#  index_debts_on_space_id  (space_id)
#  index_debts_on_status    (status)
#  index_debts_on_user_id   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (space_id => spaces.id)
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

RSpec.describe Debt, type: :model do
  let(:space) { create(:space) }

  describe "auto-close on full reimbursement" do
    it "flips to paid when total_reimbursed reaches total_lent" do
      debt = create(:debt, space: space, total_lent: 1_000, total_reimbursed: 0)
      expect(debt).to be_ongoing

      debt.update!(total_reimbursed: 1_000)
      expect(debt.reload).to be_paid
    end

    it "stays ongoing while only partially reimbursed" do
      debt = create(:debt, space: space, total_lent: 1_000, total_reimbursed: 400)
      expect(debt.reload).to be_ongoing
    end

    it "does not close a zero-value debt" do
      debt = create(:debt, space: space, total_lent: 0, total_reimbursed: 0)
      expect(debt.reload).to be_ongoing
    end
  end
end
