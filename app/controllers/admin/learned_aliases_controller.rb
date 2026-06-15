# frozen_string_literal: true

module Admin
  class LearnedAliasesController < BaseController
    include Reviewable

    private

    def reviewable_model = LearnedAlias
    def reviewable_index_path = admin_learned_aliases_path(state: params[:state])
    def approve_action = "approve_alias"
    def reject_action = "reject_alias"
  end
end
