# frozen_string_literal: true

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
