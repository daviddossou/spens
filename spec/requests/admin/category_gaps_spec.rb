# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin category gaps", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:admin) { create(:user, :admin) }
  let(:space) { admin.spaces.first }

  before { sign_in admin, scope: :user }

  def create_custom_type(name)
    type = space.transaction_types.create!(name: name, kind: "expense")
    account = space.accounts.first || create(:account, space: space)
    Transaction.create!(space: space, user: admin, transaction_type: type, account: account,
                        amount: -10, transaction_date: Date.current, description: "fal.ai")
    type
  end

  it "lists custom categories as gaps with counts and samples" do
    create_custom_type("Souscriptions & Abonnement")

    get admin_category_gaps_path
    expect(response.body).to include("Souscriptions &amp; Abonnement")
    expect(response.body).to include("fal.ai")
  end

  it "maps a gap to a taxonomy node as an active global alias" do
    create_custom_type("Souscriptions & Abonnement")

    expect do
      post map_admin_category_gaps_path,
           params: { phrase: "Souscriptions & Abonnement", taxonomy_key: "subscriptions_fun" }
    end.to change { LearnedAlias.global.active.count }.by(1)
      .and change(AdminAuditLog, :count).by(1)

    expect(LearnedAlias.global.active.last.taxonomy_key).to eq("subscriptions_fun")

    get admin_category_gaps_path
    expect(response.body).not_to include("Souscriptions &amp; Abonnement</strong>")
  end

  it "dismisses a gap so it stops appearing" do
    create_custom_type("Bidule")

    expect { post dismiss_admin_category_gaps_path, params: { phrase: "Bidule" } }
      .to change { LearnedAlias.global.rejected.count }.by(1)

    get admin_category_gaps_path
    expect(response.body).not_to include("<strong>Bidule</strong>")
  end

  it "excludes names the built-in vocabulary already resolves" do
    create_custom_type("Loyer")

    get admin_category_gaps_path
    expect(response.body).not_to include("Loyer</strong>")
  end
end
