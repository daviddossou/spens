# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatementImports::ReadJob do
  let(:import) do
    create(:statement_import, captures: Array.new(2) {
      Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/capture.png"), "image/png")
    })
  end
  let(:reader) { instance_double(StatementImports::Reader) }

  before { allow(StatementImports::Reader).to receive(:new).and_return(reader) }

  def read_with(lines)
    { "model" => "claude-haiku-5-5", "result" => { "source" => "Wave SMS", "lines" => lines } }
  end

  it "keeps every read and builds the lines" do
    allow(reader).to receive(:read).and_return(
      read_with([ { "status" => "ok", "kind" => "income", "amount" => 1000, "currency" => "XOF", "label" => "Armandine" } ])
    )

    described_class.perform_now(import.id)

    import.reload
    expect(import.status).to eq("ready")
    expect(import.reads.map { _1["capture_index"] }).to contain_exactly(0, 1)
    expect(import.lines.count).to eq(2)
  end

  it "skips a capture that fails and still reads the others" do
    calls = 0
    allow(reader).to receive(:read) do
      calls += 1
      calls == 1 ? raise(StatementImports::Reader::Error, "HTTP 529") : read_with([])
    end

    described_class.perform_now(import.id)

    expect(import.reload.status).to eq("ready")
    expect(import.reads.count { _1["error"] }).to eq(1)
  end

  it "fails the import when no capture could be read" do
    allow(reader).to receive(:read).and_raise(StatementImports::Reader::Error, "HTTP 529")

    described_class.perform_now(import.id)

    expect(import.reload).to have_attributes(status: "failed", error: "HTTP 529")
  end
end
