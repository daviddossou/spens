# frozen_string_literal: true

require "rails_helper"

RSpec.describe AmountInput do
  describe ".normalize" do
    {
      "12,50" => "12.50",
      "12.50" => "12.50",
      "0,5" => "0.5",
      "1 250,50" => "1250.50",
      "1 250 000" => "1250000",
      "1.250,50" => "1250.50",
      "1,250.50" => "1250.50",
      "1,250" => "1250",
      "1.250" => "1250",
      "1.250.000" => "1250000",
      "12,3456" => "12.3456",
      "1'250.5" => "1250.5",
      "-12,5" => "-12.5",
      "1500" => "1500",
      "" => "",
      "abc" => "abc"
    }.each do |typed, expected|
      it "turns #{typed.inspect} into #{expected.inspect}" do
        expect(described_class.normalize(typed)).to eq(expected)
      end
    end

    it "leaves non-strings alone" do
      expect(described_class.normalize(12.5)).to eq(12.5)
      expect(described_class.normalize(nil)).to be_nil
      expect(described_class.normalize(BigDecimal("3"))).to eq(BigDecimal("3"))
    end
  end

  describe "on a form" do
    let(:user) { create(:user) }
    let(:space) { user.spaces.first }

    it "casts a comma amount and passes the numericality check" do
      form = TransactionForm.new(space, amount: "12,50", fee_amount: "0,25", transaction_type_name: "Food")
      expect(form.amount).to eq(BigDecimal("12.50"))
      expect(form.fee_amount).to eq(BigDecimal("0.25"))
      form.validate
      expect(form.errors[:amount]).to be_empty
      expect(form.errors[:fee_amount]).to be_empty
    end

    it "still rejects text that is not a number" do
      form = TransactionForm.new(space, amount: "douze")
      form.validate
      expect(form.errors[:amount]).to be_present
    end
  end

  describe "on a record" do
    it "casts a comma planned amount and passes the numericality check" do
      entry = BudgetEntry.new(planned_amount: "1 250,50")
      expect(entry.planned_amount).to eq(BigDecimal("1250.50"))
      entry.validate
      expect(entry.errors[:planned_amount]).to be_empty
    end
  end
end
