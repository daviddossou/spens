# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin vocabulary review", type: :request do
  include Devise::Test::IntegrationHelpers
  include ActionView::RecordIdentifier

  let(:admin) { create(:user, :admin) }
  before { sign_in admin, scope: :user }

  it "approves a candidate alias and writes an audit row" do
    row = LearnedAlias.teach(phrase: "zoomzoom", taxonomy_key: "moto_taxi", source: "ai")

    expect { patch approve_admin_learned_alias_path(id: row.id) }
      .to change { row.reload.state }.from("candidate").to("active")
      .and change(AdminAuditLog, :count).by(1)

    expect(AdminAuditLog.last).to have_attributes(action: "approve_alias", admin_user_id: admin.id, target_id: row.id)
  end

  it "rejects a candidate keyword and writes an audit row" do
    row = LearnedKeyword.teach(phrase: "depanne", kind: "debt_out", source: "ai")

    expect { patch reject_admin_learned_keyword_path(id: row.id) }
      .to change { row.reload.state }.to("rejected")
      .and change(AdminAuditLog, :count).by(1)

    expect(AdminAuditLog.last.action).to eq("reject_keyword")
  end

  it "approving makes an alias visible to the rules (active_index)" do
    row = LearnedAlias.teach(phrase: "zoomzoom", taxonomy_key: "moto_taxi", source: "ai")

    expect { patch approve_admin_learned_alias_path(id: row.id) }
      .to change { LearnedAlias.active_index }.from({}).to("zoomzoom" => "moto_taxi")
  end

  it "replaces the row over turbo_stream" do
    row = LearnedKeyword.teach(phrase: "depanne", kind: "debt_out", source: "ai")

    patch approve_admin_learned_keyword_path(id: row.id), headers: { "Accept" => "text/vnd.turbo-stream.html" }

    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include("turbo-stream")
    expect(response.body).to include(dom_id(row))
  end
end
