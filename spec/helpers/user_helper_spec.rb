# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserHelper, type: :helper do
  describe "#user_display_name" do
    context "when user has first_name" do
      let(:user) { create(:user, first_name: "John", last_name: "Doe", email: "john@example.com") }

      it "returns full name" do
        expect(helper.user_display_name(user)).to eq("John Doe")
      end

      it "strips extra whitespace" do
        user.last_name = ""
        expect(helper.user_display_name(user)).to eq("John")
      end
    end

    context "when user has no first_name" do
      let(:user) { build(:user, first_name: "", last_name: "", email: "john@example.com") }

      it "returns email" do
        expect(helper.user_display_name(user)).to eq("john@example.com")
      end
    end

    context "when first_name is blank" do
      let(:user) { build(:user, first_name: "", last_name: "Doe", email: "john@example.com") }

      it "returns email" do
        expect(helper.user_display_name(user)).to eq("john@example.com")
      end
    end
  end
end
