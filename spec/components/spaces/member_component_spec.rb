# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spaces::MemberComponent, type: :component do
  let(:owner) { create(:user, first_name: "Awa", last_name: "Diop", email: "awa@example.com") }
  let(:space) { owner.spaces.first }
  let(:member) { owner }
  let(:full_name) { "Awa Diop" }

  let(:rendered) { render_inline(described_class.new(space: space, member: member, full_name: full_name)) }

  it "shows the name, the email under it and the initial as avatar" do
    expect(rendered.at_css(".member-card__name").text).to eq("Awa Diop")
    expect(rendered.at_css(".member-card__email").text).to eq("awa@example.com")
    avatar = rendered.at_css(".member-card__avatar")
    expect(avatar.text).to eq("A")
    expect(avatar["aria-hidden"]).to eq("true")
  end

  it "badges the space owner" do
    expect(rendered.at_css(".member-card__badge--owner").text).to eq("Owner")
  end

  context "with a plain member without a name" do
    let(:member) { build_stubbed(:user, email: "kofi@example.com") }
    let(:full_name) { "" }

    it "falls back to the email and shows no owner badge" do
      expect(rendered.at_css(".member-card__name").text).to eq("kofi@example.com")
      expect(rendered.at_css(".member-card__email")).to be_nil
      expect(rendered.at_css(".member-card__avatar").text).to eq("K")
      expect(rendered.at_css(".member-card__badge--owner")).to be_nil
    end
  end
end
