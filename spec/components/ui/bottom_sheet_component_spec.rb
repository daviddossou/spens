# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::BottomSheetComponent, type: :component do
  let(:rendered) { render_inline(described_class.new) }

  it "mounts the bottom-sheet Stimulus controller with its backdrop and panel targets" do
    root = rendered.at_css(".bottom-sheet")
    expect(root["data-controller"]).to eq("bottom-sheet")
    expect(root.at_css(".bottom-sheet__backdrop")["data-bottom-sheet-target"]).to eq("backdrop")
    expect(root.at_css(".bottom-sheet__backdrop")["data-action"]).to eq("click->bottom-sheet#close")
    expect(root.at_css(".bottom-sheet__panel")["data-bottom-sheet-target"]).to eq("panel")
  end

  it "renders a labelled close button" do
    button = rendered.at_css("button.bottom-sheet__close")
    expect(button["aria-label"]).to eq("Close")
    expect(button["data-action"]).to eq("click->bottom-sheet#close")
  end

  it "hosts the modal turbo frame wired to the sheet lifecycle" do
    frame = rendered.at_css("turbo-frame#modal")
    expect(frame["data-bottom-sheet-target"]).to eq("frame")
    expect(frame["data-action"]).to include("turbo:frame-load->bottom-sheet#frameLoaded")
    expect(frame["data-action"]).to include("turbo:frame-render->bottom-sheet#frameRendered")
    expect(frame["data-action"]).to include("turbo:frame-missing->bottom-sheet#frameMissing")
  end
end
