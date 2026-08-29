# frozen_string_literal: true

require "rails_helper"

RSpec.describe Accounts::ArchivesController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, name: "Wave") }

  before { sign_in user, scope: :user }

  describe "POST create" do
    it "archives the account and keeps it out of the active scope" do
      post account_archive_path(account_id: account.id)

      expect(account.reload.archived?).to be(true)
      expect(user.spaces.first.accounts.active).not_to include(account)
      expect(user.spaces.first.accounts.archived).to include(account)
    end
  end

  describe "DELETE destroy" do
    it "brings an archived account back" do
      account.archive!

      delete account_archive_path(account_id: account.id)

      expect(account.reload.archived?).to be(false)
      expect(user.spaces.first.accounts.active).to include(account)
    end
  end
end
