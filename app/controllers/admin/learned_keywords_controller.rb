# frozen_string_literal: true

module Admin
  class LearnedKeywordsController < BaseController
    include Reviewable

    private

    def reviewable_model = LearnedKeyword
    def reviewable_index_path = admin_learned_keywords_path(state: params[:state])
    def approve_action = "approve_keyword"
    def reject_action = "reject_keyword"
    def restore_action = "restore_keyword"
  end
end
