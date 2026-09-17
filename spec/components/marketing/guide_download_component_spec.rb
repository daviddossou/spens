# frozen_string_literal: true

require "rails_helper"

RSpec.describe Marketing::GuideDownloadComponent, type: :component do
  let(:rendered) do
    render_inline(described_class.new(url: "/guide-spens.pdf", filename: "Guide-Spens.pdf", label: "Download the guide",
                                      placement: "hero", classes: "landing-btn-light guide-btn-download"))
  end
  let(:link) { rendered.at_css("a") }

  it "downloads the PDF under its public file name, unstyled but for the given classes" do
    expect(link["href"]).to eq("/guide-spens.pdf")
    expect(link["download"]).to eq("Guide-Spens.pdf")
    expect(link["class"]).to eq("landing-btn-light guide-btn-download")
    expect(link["type"]).to be_nil
  end

  it "records the lead and redirects to the thank-you page after the download" do
    expect(link["data-controller"]).to eq("landing--guide-download")
    expect(link["data-action"]).to eq("landing--guide-download#redirect landing--meta-events#lead")
    expect(link["data-landing--meta-events-placement-param"]).to eq("hero")
    expect(link["data-landing--guide-download-url-value"]).to eq("/guide/thanks")
  end

  it "shows the label with a decorative arrow" do
    expect(link.text.strip).to start_with("Download the guide")
    arrow = link.at_css(".guide-btn-download__arrow")
    expect(arrow["aria-hidden"]).to eq("true")
  end

  it "keeps the placement it was given" do
    html = render_inline(described_class.new(url: "/x.pdf", filename: "x.pdf", label: "Get it", placement: "final", classes: "c"))
    expect(html.at_css("a")["data-landing--meta-events-placement-param"]).to eq("final")
  end
end
