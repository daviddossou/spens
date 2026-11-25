# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatementImports::PurgeCapturesJob do
  it "deletes captures past the retention period and keeps the import and its lines" do
    old = create(:statement_import, created_at: 91.days.ago)
    old.lines.create!(position: 1, capture_index: 0, status: "ok")
    recent = create(:statement_import, created_at: 89.days.ago)

    described_class.perform_now

    expect(old.reload.captures).not_to be_attached
    expect(old.lines.count).to eq(1)
    expect(recent.reload.captures).to be_attached
  end
end
