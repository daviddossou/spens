# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatementImports::Reader do
  let(:user) { create(:user, first_name: "David", last_name: "Dossou") }
  let(:space) { user.spaces.first }
  let(:import) { create(:statement_import, user: user, space: space) }
  let(:blob) { import.captures.first.blob }
  let(:reader) { described_class.new(space: space, user: user, today: Date.new(2026, 11, 24)) }

  before do
    allow(described_class).to receive(:config).and_return({ api_key: "test-key", model: "claude-haiku-5-5" })
    create(:account, space: space, name: "👛 Espèces")
  end

  it "sends the capture with the user's context and returns the raw tool input" do
    sent = nil
    allow(reader).to receive(:post_json) do |body|
      sent = body
      { "model" => "claude-haiku-5-5", "stop_reason" => "tool_use", "usage" => { "input_tokens" => 10, "output_tokens" => 5 },
        "content" => [ { "type" => "tool_use", "name" => "record_lines", "input" => { "source" => "Wave SMS", "lines" => [] } } ] }
    end

    read = reader.read(blob)

    expect(read).to include("model" => "claude-haiku-5-5", "result" => { "source" => "Wave SMS", "lines" => [] })
    expect(read["usage"]).to eq("input_tokens" => 10, "output_tokens" => 5)
    expect(sent[:thinking]).to eq(type: "disabled")
    expect(sent[:messages].first[:content].first).to include(type: "image")
    expect(sent[:system]).to include("David Dossou", "Espèces", "2026-11-24")
  end

  it "raises when the model does not call the tool" do
    allow(reader).to receive(:post_json).and_return("stop_reason" => "refusal", "content" => [])

    expect { reader.read(blob) }.to raise_error(described_class::Error, /refusal/)
  end
end
