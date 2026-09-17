# frozen_string_literal: true

require "rails_helper"

RSpec.describe Accounts::BalanceAdjustmentComponent, type: :component do
  let(:account) { build_stubbed(:account) }
  let(:rendered) { render_inline(described_class.new(account: account)) }

  it "starts hidden and exposes the account-form targets" do
    root = rendered.at_css(".account-gap")
    expect(root["class"]).to include("hidden")
    expect(root["data-account-form-target"]).to eq("gap")
    expect(rendered.at_css(".account-gap__amount")["data-account-form-target"]).to eq("gapAmount")
    expect(rendered.at_css(".account-gap__hint[data-account-form-target='recalibrateHint']")).to be_present
    expect(rendered.at_css(".account-gap__hint[data-account-form-target='incomeHint']")).to be_present
  end

  it "preselects the recalibrate option" do
    option = rendered.at_css(".account-gap__option--selected")
    expect(option.text).to include("I'm not sure, recalibrate")
    expect(option.at_css(".account-gap__check")["aria-hidden"]).to eq("true")
  end

  it "keeps the income option hidden until the controller fills its link, inside the modal frame" do
    link = rendered.at_css("a[data-account-form-target='incomeLink']")
    expect(link["class"]).to include("hidden")
    expect(link["href"]).to eq("#")
    expect(link["data-turbo-frame"]).to eq("modal")
    expect(link.text).to include("I received money")
  end

  it "links the fix option to the account's movements" do
    link = rendered.css("a.account-gap__option").last
    expect(link["href"]).to eq("/accounts/#{account.id}")
    expect(link.text).to include("I mis-entered a transaction")
    expect(link.text).to include("Go to the account's movements to fix it")
  end

  it "asks where the gap comes from" do
    expect(rendered.at_css(".account-gap__question").text).to eq("Where's the gap from?")
    expect(rendered.to_html).not_to include("translation missing")
  end
end
