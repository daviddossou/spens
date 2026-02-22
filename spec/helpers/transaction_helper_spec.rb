# frozen_string_literal: true

require "rails_helper"

RSpec.describe TransactionHelper, type: :helper do
  describe "#transaction_icon_class" do
    it "delegates to TransactionIconService with transaction-show scope" do
      expect(TransactionIconService).to receive(:icon_class).with("income", scope: "transaction-show")
      helper.transaction_icon_class("income")
    end
  end

  describe "#transaction_header_class" do
    it "delegates to TransactionIconService" do
      expect(TransactionIconService).to receive(:header_class).with("income")
      helper.transaction_header_class("income")
    end
  end

  describe "#transaction_amount_class" do
    it "delegates to TransactionIconService with transaction-show scope" do
      expect(TransactionIconService).to receive(:amount_class).with("expense", scope: "transaction-show")
      helper.transaction_amount_class("expense")
    end
  end

  describe "#transaction_badge_class" do
    it "delegates to TransactionIconService" do
      expect(TransactionIconService).to receive(:badge_class).with("debt_in")
      helper.transaction_badge_class("debt_in")
    end
  end

  describe "#transaction_icon_svg" do
    it "delegates to TransactionIconService" do
      expect(TransactionIconService).to receive(:icon_svg).with("transfer_in")
      helper.transaction_icon_svg("transfer_in")
    end
  end

  describe "#transaction_amount_prefix" do
    it "delegates to TransactionIconService" do
      expect(TransactionIconService).to receive(:amount_prefix).with("income")
      helper.transaction_amount_prefix("income")
    end
  end
end
