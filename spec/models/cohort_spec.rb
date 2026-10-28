# frozen_string_literal: true

require "rails_helper"

RSpec.describe Cohort, type: :model do
  describe ".activate!" do
    it "makes the named cohort the only active one, creating it if needed" do
      create(:cohort, campaign: "cohorte-nov", whatsapp_group_url: "https://chat.whatsapp.com/OLD")

      cohort = described_class.activate!("cohorte-dec", group_url: "https://chat.whatsapp.com/NEW")

      expect(cohort).to have_attributes(campaign: "cohorte-dec", active: true, whatsapp_group_url: "https://chat.whatsapp.com/NEW")
      expect(described_class.current).to eq(cohort)
      expect(described_class.find_by(campaign: "cohorte-nov")).not_to be_active
    end

    it "keeps the group URL when none is given" do
      create(:cohort, campaign: "cohorte-nov", active: false, whatsapp_group_url: "https://chat.whatsapp.com/KEEP")

      expect(described_class.activate!("cohorte-nov").whatsapp_group_url).to eq("https://chat.whatsapp.com/KEEP")
    end
  end

  describe "#open?" do
    it "offers the group only with a URL and while registrations are open" do
      expect(build(:cohort)).to be_open
      expect(build(:cohort, registrations_closed: true)).not_to be_open
      expect(build(:cohort, whatsapp_group_url: nil)).not_to be_open
    end
  end
end
