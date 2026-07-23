# frozen_string_literal: true

# The space's own learned vocabulary (personal aliases + keywords) — the safety valve behind
# the invisible learning: the user can see, retarget, or delete what the space has learned.
class Spaces::MappingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_space

  def index
    @aliases = @space.learned_aliases.active.order(updated_at: :desc)
    @keywords = @space.learned_keywords.active.order(updated_at: :desc)
  end

  def update
    mapping = @space.learned_aliases.find(params[:id])
    if TransactionTaxonomy.exists?(params[:taxonomy_key])
      mapping.update!(taxonomy_key: params[:taxonomy_key])
      redirect_to space_mappings_path(space_id: @space.id), notice: t(".success"), status: :see_other
    else
      redirect_to space_mappings_path(space_id: @space.id), alert: t(".invalid_category"), status: :see_other
    end
  end

  def destroy
    mapping = find_mapping
    mapping.destroy!
    redirect_to space_mappings_path(space_id: @space.id), notice: t(".success"), status: :see_other
  end

  private

  def set_space
    @space = current_user.spaces.find(params[:space_id])
  end

  # One screen manages both learned models; the row's type rides along as a param.
  def find_mapping
    scope = params[:type] == "keyword" ? @space.learned_keywords : @space.learned_aliases
    scope.find(params[:id])
  end
end
