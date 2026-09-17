# frozen_string_literal: true

require "rails_helper"

RSpec.describe Accounts::ArchivedRowComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:account) { create(:account, space: space, name: "Old wallet", balance: 12_500, archived_at: Time.zone.local(2026, 3, 4, 10)) }

  before { stub_current_space(space) }

  let(:rendered) { render_inline(described_class.new(account: account)) }

  it "shows the name, the archive date and the full balance" do
    expect(rendered.at_css(".account-archived-row__name").text).to eq("Old wallet")
    sub = rendered.at_css(".account-archived-row__sub").text
    expect(sub).to include("March 04, 2026")
    expect(sub).to include("12,500")
    expect(sub).to include("FCFA")
    expect(sub).not_to include("translation missing")
  end

  it "links the reactivate action to the archive route with a DELETE turbo method" do
    link = rendered.at_css("a.account-archived-row__action")
    expect(link.text).to eq("Reactivate")
    expect(link["href"]).to eq("/accounts/#{account.id}/archive")
    expect(link["data-turbo-method"]).to eq("delete")
  end
end
