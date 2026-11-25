# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatementImports::Tracking do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:import) do
    create(:statement_import, user: user, space: space, status: "ready", captures: [ image_upload ]).tap do |i|
      i.captures.attach(io: StringIO.new(blank_pdf(3)), filename: "s.pdf", content_type: "application/pdf", metadata: { "pages" => 3 })
    end
  end
  let(:events) { [] }

  before { allow(Analytics).to receive(:track) { |_user, event, props| events << [ event, props ] } }

  def line(**attrs)
    import.lines.create!({ position: import.lines.count + 1, capture_index: 0, status: "ok", kind: "expense", amount: -2000,
                           transaction_type_name: "Groceries", category_source: "rules" }.merge(attrs))
  end

  it "says what was sent: files, images, PDFs and their pages" do
    described_class.started(import, origin: "gallery")

    event, props = events.last
    expect(event).to eq("statement_import_started")
    expect(props).to include(origin: "gallery", files: 2, images: 1, pdfs: 1, pdf_pages: 3, slots: 4)
  end

  it "measures the reading: cost, failures, lines, set-aside reasons and how lines were classified" do
    import.update!(model: "claude-haiku-5-5", source: "MTN MoMo SMS", reads: [
      { "capture_index" => 0, "seconds" => 2.1, "usage" => { "input_tokens" => 4000, "output_tokens" => 400 } },
      { "capture_index" => 1, "error" => "HTTP 529" }
    ])
    line
    line(category_source: "ai")
    line(category_source: "fallback")
    line(status: "declined")

    described_class.read(import, seconds: 3.24)

    _, props = events.last
    expect(props).to include(status: "ready", seconds: 3.2, captures_failed: 1, input_tokens: 4000, output_tokens: 400,
                             detected_source: "MTN MoMo SMS", lines_read: 4, lines_proposed: 3,
                             category_rules: 1, category_ai: 1, category_fallback: 1)
    expect(props[:ignored_reasons]).to eq("declined" => 1)
    expect(props[:review_reasons]).to include("fallback_category" => 1, "uncertain_category" => 1)
  end

  it "never sends amounts, labels or file names" do
    line(label: "Carrefour Market", amount: -12_345)

    described_class.read(import, seconds: 1)

    sent = events.to_s
    expect(sent).not_to include("Carrefour", "12345", "s.pdf", "capture.png")
  end
end
