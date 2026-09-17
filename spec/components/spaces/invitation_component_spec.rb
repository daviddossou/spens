# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spaces::InvitationComponent, type: :component do
  let(:invitation) do
    Invitation.new(email: "marie@example.com", created_at: Time.zone.local(2026, 2, 3, 9))
  end

  let(:rendered) { render_inline(described_class.new(invitation: invitation)) }

  it "renders a pending member card with the email as name" do
    expect(rendered.at_css(".member-card--pending")).to be_present
    expect(rendered.at_css(".member-card__name").text).to eq("marie@example.com")
  end

  it "uses the email's initial as a decorative avatar" do
    avatar = rendered.at_css(".member-card__avatar--pending")
    expect(avatar.text).to eq("M")
    expect(avatar["aria-hidden"]).to eq("true")
  end

  it "dates the invitation and flags it pending" do
    expect(rendered.at_css(".member-card__email").text).to eq("Invited Feb 03")
    expect(rendered.at_css(".member-card__badge--pending").text).to eq("Pending")
  end
end
