# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spaces::MappingsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  before { sign_in user, scope: :user }

  describe "GET #index" do
    it "lists the space's personal mappings" do
      LearnedAlias.personal_teach(space: space, phrase: "chez l'indien", taxonomy_key: "restaurant_maquis")
      LearnedKeyword.personal_teach(space: space, phrase: "soutra", kind: "debt_out")

      get space_mappings_path(space_id: space.id)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("chez l&#39;indien")
      expect(response.body).to include("soutra")
    end

    it "renders the empty state when nothing was learned" do
      get space_mappings_path(space_id: space.id)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t("spaces.mappings.index.empty_title"))
    end

    it "denies access to a space the user is not a member of" do
      stranger = create(:user)
      get space_mappings_path(space_id: stranger.spaces.first.id)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH #update" do
    it "retargets a personal alias" do
      row = LearnedAlias.personal_teach(space: space, phrase: "carrefour", taxonomy_key: "groceries")

      patch space_mapping_path(space_id: space.id, id: row.id), params: { taxonomy_key: "monthly_provisions" }

      expect(row.reload.taxonomy_key).to eq("monthly_provisions")
    end
  end

  describe "DELETE #destroy" do
    it "forgets a personal alias" do
      row = LearnedAlias.personal_teach(space: space, phrase: "carrefour", taxonomy_key: "groceries")

      expect do
        delete space_mapping_path(space_id: space.id, id: row.id)
      end.to change(LearnedAlias, :count).by(-1)
    end

    it "forgets a personal keyword via type=keyword" do
      row = LearnedKeyword.personal_teach(space: space, phrase: "soutra", kind: "debt_out")

      expect do
        delete space_mapping_path(space_id: space.id, id: row.id, type: "keyword")
      end.to change(LearnedKeyword, :count).by(-1)
    end
  end
end
