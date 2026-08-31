# frozen_string_literal: true

module Admin
  # Read-only JSON snapshot of the category tree for review and external tooling.
  #   GET /admin/taxonomy_export.json
  #   GET /admin/taxonomy_export.json?kind=expense&gaps=false
  class TaxonomyExportsController < BaseController
    def show
      render json: TaxonomyExport.call(kind: kind_param, gaps: gaps_param, gap_limit: gap_limit_param)
    end

    private

    def kind_param
      params[:kind].presence_in(TransactionTaxonomy::KINDS)
    end

    def gaps_param
      params[:gaps].to_s != "false"
    end

    def gap_limit_param
      limit = params[:gap_limit].to_i
      limit.positive? ? [ limit, 200 ].min : 50
    end

    # JSON clients get a status, not a redirect to the marketing root.
    def require_admin!
      return if current_user&.admin?

      render json: { error: "forbidden" }, status: :forbidden
    end
  end
end
