# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatementImportsController, type: :request do
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let!(:bank) { create(:account, space: space, name: "Bank") }

  before do
    allow(StatementImports::Reader).to receive(:enabled?).and_return(true)
    sign_in user, scope: :user
  end

  def latest
    StatementImport.order(:created_at).last
  end

  it "is not reachable by users without access" do
    allow_any_instance_of(User).to receive(:can_use_statement_import?).and_return(false)

    post statement_imports_path, params: { captures: [ image_upload ] }

    expect(response).to have_http_status(:not_found)
  end

  describe "POST create" do
    it "keeps the chosen captures as a draft on the last used account, and reads nothing yet" do
      expect do
        post statement_imports_path, params: { captures: [ image_upload, image_upload ] }
      end.not_to have_enqueued_job(StatementImports::ReadJob)

      expect(response).to redirect_to(statement_import_path(id: latest.id))
      expect(latest).to have_attributes(status: "draft", account: bank, user: user)
      expect(latest.captures.count).to eq(2)
    end

    it "keeps the first five of a larger pick" do
      post statement_imports_path, params: { captures: Array.new(7) { image_upload } }

      expect(latest.captures.count).to eq(5)
      expect(flash[:alert]).to be_nil
    end

    it "counts a PDF one slot per page" do
      post statement_imports_path, params: { captures: [ pdf_upload(3), image_upload ] }

      expect(latest.slots_used).to eq(4)
    end

    it "leaves out a PDF longer than the room left, and says why" do
      post statement_imports_path, params: { captures: [ image_upload, pdf_upload(6) ] }

      expect(latest.captures.count).to eq(1)
      expect(flash[:alert]).to include("6")
    end

    it "refuses files it cannot read" do
      post statement_imports_path, params: { captures: [ Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/not_a_capture.txt"), "text/plain") ] }

      expect(response).to redirect_to(dashboard_path)
      expect(StatementImport.count).to eq(0)
    end
  end

  describe "the captures screen" do
    let(:import) { create(:statement_import, user: user, space: space, status: "draft", captures: Array.new(5) { image_upload }) }

    it "shows the limit once five slots are used" do
      get statement_import_path(id: import.id)

      expect(response.body).to include("5 / 5", "si-tile--limit")
      expect(response.body).not_to include("bottom-nav")
    end

    it "removes a capture, then adds one back" do
      delete statement_import_capture_path(statement_import_id: import.id, id: import.captures.first.id)
      expect(import.reload.captures.count).to eq(4)

      post statement_import_captures_path(statement_import_id: import.id), params: { captures: [ image_upload, image_upload ] }
      expect(import.reload.captures.count).to eq(5)
    end
  end

  describe "POST analyze" do
    let(:import) { create(:statement_import, user: user, space: space, status: "draft") }

    it "starts the reading on the chosen account" do
      momo = create(:account, space: space, name: "MoMo")

      expect do
        post analyze_statement_import_path(id: import.id), params: { statement_import: { account_name: "MoMo" } }
      end.to have_enqueued_job(StatementImports::ReadJob).with(import.id)

      expect(import.reload).to have_attributes(status: "reading", account: momo)
    end

    it "needs an account" do
      post analyze_statement_import_path(id: import.id), params: { statement_import: { account_name: "" } }

      expect(import.reload.status).to eq("draft")
    end
  end

  describe "the analysis screen" do
    let(:import) { create(:statement_import, user: user, space: space, status: "reading", captures: [ image_upload, image_upload ]) }

    it "shows each capture as it is read, then where to go once done" do
      import.update!(reads: [ { "capture_index" => 1, "result" => { "lines" => [ {}, {} ] } } ])

      get progress_statement_import_path(id: import.id)
      expect(response.body).to include("si-card--reading", "si-card--done", "2 lines read")
      expect(response.body).not_to include("data-poll-done-url")

      import.update!(status: "ready")
      get progress_statement_import_path(id: import.id)
      expect(response.body).to include("data-poll-done-url")
    end

    it "cancels the import" do
      delete statement_import_path(id: import.id)

      expect(response).to redirect_to(dashboard_path)
      expect(StatementImport.exists?(import.id)).to be(false)
    end
  end

  it "never shows another user's import" do
    other = create(:statement_import)

    get statement_import_path(id: other.id)

    expect(response).to have_http_status(:not_found)
  end
end
