# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatementImport do
  let(:user) { create(:user) }

  def capture(name = "capture.png", type = "image/png")
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/#{name}"), type)
  end

  it "needs at least one capture" do
    expect(build(:statement_import, user: user, captures: [])).not_to be_valid
  end

  it "takes at most five captures" do
    expect(build(:statement_import, user: user, captures: Array.new(6) { capture })).not_to be_valid
    expect(build(:statement_import, user: user, captures: Array.new(5) { capture })).to be_valid
  end

  it "only takes images and PDFs" do
    expect(build(:statement_import, user: user, captures: [ capture("not_a_capture.txt", "text/plain") ])).not_to be_valid
  end

  it "survives the deletion of the account it was read for" do
    account = create(:account, space: user.spaces.first)
    import = create(:statement_import, user: user, account: account)
    import.lines.create!(position: 1, capture_index: 0, status: "ok", account: account)

    account.destroy!

    expect(import.reload.account).to be_nil
    expect(import.lines.first.account).to be_nil
  end
  it "counts a PDF one slot per page" do
    import = create(:statement_import, user: user, status: "draft")
    import.captures.attach(io: StringIO.new(blank_pdf(3)), filename: "s.pdf", content_type: "application/pdf", metadata: { "pages" => 3 })

    expect(import.slots_used).to eq(4)
    expect(import.room_left).to eq(1)
    expect(import).not_to be_full
  end

  it "starts the reading only from a draft with captures and an account" do
    import = create(:statement_import, user: user, status: "draft")
    account = create(:account, space: import.space)

    expect(import.analyze!(nil)).to be(false)
    expect { expect(import.analyze!(account)).to be(true) }.to have_enqueued_job(StatementImports::ReadJob)
    expect(import.reload).to have_attributes(status: "reading", account: account)
    expect(import.analyze!(account)).to be(false)
  end
end
