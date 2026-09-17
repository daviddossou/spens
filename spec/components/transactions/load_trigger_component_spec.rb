# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::LoadTriggerComponent, type: :component do
  let(:rendered) { render_inline(described_class.new) }

  it "renders the infinite-scroll sentinel" do
    trigger = rendered.at_css("#infinite-scroll-trigger")
    expect(trigger["data-infinite-scroll-target"]).to eq("trigger")
    expect(trigger["class"]).to eq("dashboard__load-trigger")
    expect(trigger.text).to be_empty
  end
end
