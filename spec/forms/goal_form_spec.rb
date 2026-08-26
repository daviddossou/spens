# frozen_string_literal: true

require "rails_helper"

RSpec.describe GoalForm, type: :model do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:valid_attributes) do
    { goal_name: "Trip to Zanzibar", account_name: "Travel Fund", current_balance: 1_000, target_amount: 5_000 }
  end
  let(:form) { described_class.new(space, valid_attributes) }

  describe "validations" do
    it "is valid with the full set" do
      expect(form).to be_valid
    end

    it "requires a goal name" do
      form.goal_name = nil
      expect(form).not_to be_valid
      expect(form.errors[:goal_name]).to be_present
    end

    it "requires an account name" do
      form.account_name = nil
      expect(form).not_to be_valid
    end

    it "allows a blank target amount (name it now, set a target later)" do
      form.target_amount = nil
      expect(form).to be_valid
    end

    it "allows a blank current balance" do
      form.current_balance = nil
      expect(form).to be_valid
    end

    it "rejects a target below the current balance" do
      form.current_balance = 2_000
      form.target_amount = 1_000
      expect(form).not_to be_valid
      expect(form.errors[:target_amount]).to include(I18n.t("errors.messages.goal_must_be_greater"))
    end

    it "rejects a past deadline" do
      travel_to Date.new(2026, 6, 1) do
        form.deadline = Date.new(2026, 5, 1)
        expect(form).not_to be_valid
        expect(form.errors[:deadline]).to be_present
      end
    end
  end

  describe "#submit" do
    it "creates the account and the goal" do
      expect { form.submit }.to change(Account, :count).by(1).and change(Goal, :count).by(1)

      goal = Goal.order(:created_at).last
      expect(goal.name).to eq("Trip to Zanzibar")
      expect(goal.target_amount).to eq(5_000)
      expect(goal.account.name).to eq("Travel Fund")
    end

    it "creates a goal with no target yet" do
      form = described_class.new(space, valid_attributes.except(:target_amount))
      expect { form.submit }.to change(Goal, :count).by(1)
      expect(Goal.order(:created_at).last.target_amount).to be_nil
    end

    it "adjusts the account balance when a starting balance is given" do
      expect { form.submit }.to change { space.accounts.find_by(name: "Travel Fund")&.balance }.to(1_000)
    end

    it "updates the existing goal on re-submit for the same account" do
      form.submit
      account = space.accounts.find_by(name: "Travel Fund")

      described_class.new(space, valid_attributes.merge(target_amount: 8_000)).submit
      expect(account.reload.goal.target_amount).to eq(8_000)
      expect(space.goals.count).to eq(1)
    end

    it "builds a bounded budget line when a deadline is set" do
      travel_to Date.new(2026, 1, 10) do
        described_class.new(space, valid_attributes.merge(current_balance: 0, target_amount: 30_000,
                                                          deadline: Date.new(2026, 6, 30))).submit
        account = space.accounts.find_by(name: "Travel Fund")
        line = space.budget_items.find_by(kind: "transfer", to_account_id: account.id, from_account_id: nil)
        expect(line.amount).to eq(5_000) # 30000 / 6 months
        expect(line.ends_on).to eq(Date.new(2026, 6, 30))
      end
    end
  end
end
