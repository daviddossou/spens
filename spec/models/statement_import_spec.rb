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
end
