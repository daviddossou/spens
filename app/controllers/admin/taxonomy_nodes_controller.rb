# frozen_string_literal: true

module Admin
  # CRUD over the category tree (taxonomy_nodes). Keys are immutable; nodes referenced by
  # transaction_types can only be deactivated, never destroyed. The index is a collapsible
  # tree with search, ↑↓ reordering, and inline rename (turbo row swaps).
  class TaxonomyNodesController < BaseController
    before_action :set_node, only: [ :edit, :update, :destroy, :activate, :deactivate,
                                     :move_up, :move_down, :rename ]

    def index
      @kind = TransactionTaxonomy::KINDS.include?(params[:kind]) ? params[:kind] : "expense"
      @q = params[:q].to_s.strip
      @parents = TaxonomyNode.parents.where(kind: @kind).ordered.to_a
      @children = TaxonomyNode.where(kind: @kind).where.not(parent_key: nil).ordered.group_by(&:parent_key)
      @reference_counts = TransactionType.where(template_key: TaxonomyNode.select(:key)).group(:template_key).count
      @alias_counts = LearnedAlias.global.active.group(:taxonomy_key).count

      if @q.present?
        matches = ->(n) { [ n.name_en, n.name_fr, n.key ].any? { |v| CategoryText.normalize(v).include?(CategoryText.normalize(@q)) } }
        @parents = @parents.select { |p| matches.call(p) || (@children[p.key] || []).any?(&matches) }
        @open_keys = @parents.map(&:key)
      else
        @open_keys = []
      end
    end

    def new
      @node = TaxonomyNode.new(kind: params[:kind].presence_in(TransactionTaxonomy::KINDS) || "expense",
                               parent_key: params[:parent_key].presence)
    end

    def create
      @node = TaxonomyNode.new(create_params)
      @node.position = next_position(@node)
      if @node.save
        record_admin_action("create_taxonomy_node", target: @node, metadata: { key: @node.key })
        redirect_to admin_taxonomy_nodes_path(kind: @node.kind), notice: t("admin.taxonomy.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @node.update(update_params)
        record_admin_action("update_taxonomy_node", target: @node, metadata: { key: @node.key })
        respond_to do |format|
          format.turbo_stream { render_row_replace }
          format.html { redirect_to admin_taxonomy_nodes_path(kind: @node.kind), notice: t("admin.taxonomy.updated") }
        end
      else
        respond_to do |format|
          format.turbo_stream { render_row_replace(partial: "node_row_form") }
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    # Turbo row swap: renders the inline rename form in place of the row (or the row back
    # again when cancelling).
    def rename
      render_row_replace(partial: params[:cancel].present? ? "node_row" : "node_row_form")
    end

    def move_up = move(-1)
    def move_down = move(1)

    # Drag-and-drop drop target: assigns positions from the received key order. Refuses
    # mixed groups — every key must share the same kind and parent.
    def reorder
      nodes = TaxonomyNode.where(key: Array(params[:keys])).to_a
      return head :unprocessable_entity if nodes.empty? ||
                                           nodes.map { |n| [ n.kind, n.parent_key ] }.uniq.size > 1

      by_key = nodes.index_by(&:key)
      Array(params[:keys]).each_with_index { |key, i| by_key[key]&.update_column(:position, i) }
      TransactionTaxonomy.reload!
      record_admin_action("update_taxonomy_node", metadata: { reordered: nodes.size, parent: nodes.first.parent_key })
      head :ok
    end

    def deactivate
      if @node.protected_key?
        redirect_to admin_taxonomy_nodes_path(kind: @node.kind), alert: t("admin.taxonomy.protected")
      elsif @node.parent? && @node.children.active.exists?
        redirect_to admin_taxonomy_nodes_path(kind: @node.kind), alert: t("admin.taxonomy.has_active_children")
      else
        @node.update!(active: false)
        record_admin_action("deactivate_taxonomy_node", target: @node, metadata: { key: @node.key })
        redirect_to admin_taxonomy_nodes_path(kind: @node.kind), notice: t("admin.taxonomy.deactivated")
      end
    end

    def activate
      @node.update!(active: true)
      record_admin_action("activate_taxonomy_node", target: @node, metadata: { key: @node.key })
      redirect_to admin_taxonomy_nodes_path(kind: @node.kind), notice: t("admin.taxonomy.activated")
    end

    def destroy
      if @node.destroy
        record_admin_action("destroy_taxonomy_node", target: nil, metadata: { key: @node.key })
        redirect_to admin_taxonomy_nodes_path(kind: @node.kind), notice: t("admin.taxonomy.destroyed")
      else
        redirect_to admin_taxonomy_nodes_path(kind: @node.kind), alert: @node.errors.full_messages.to_sentence
      end
    end

    private

    def set_node
      @node = TaxonomyNode.find(params[:id])
    end

    # Swap positions with the previous/next sibling. Normalizes the sequence first so
    # imported duplicates (several 0s) can't make the swap a no-op.
    def move(direction)
      siblings = TaxonomyNode.where(kind: @node.kind, parent_key: @node.parent_key).ordered.to_a
      siblings.each_with_index { |n, i| n.update_column(:position, i) unless n.position == i }
      idx = siblings.index { |n| n.id == @node.id }
      other = idx + direction >= 0 ? siblings[idx + direction] : nil
      if other
        @node.update_column(:position, idx + direction)
        other.update_column(:position, idx)
        record_admin_action("update_taxonomy_node", target: @node, metadata: { key: @node.key, moved: direction })
      end
      TransactionTaxonomy.reload!
      redirect_to admin_taxonomy_nodes_path(kind: @node.kind, q: params[:q].presence, anchor: helpers.dom_id(@node))
    end

    def render_row_replace(partial: "node_row")
      render turbo_stream: turbo_stream.replace(@node, partial: "admin/taxonomy_nodes/#{partial}", locals: row_locals(@node))
    end

    def row_locals(node)
      siblings = TaxonomyNode.where(kind: node.kind, parent_key: node.parent_key).ordered.pluck(:id)
      {
        node: node,
        first: siblings.first == node.id,
        last: siblings.last == node.id,
        reference_count: TransactionType.where(template_key: node.key).count,
        alias_count: LearnedAlias.global.active.where(taxonomy_key: node.key).count
      }
    end

    def create_params
      params.require(:taxonomy_node).permit(:key, :kind, :parent_key, :name_en, :name_fr)
    end

    def update_params
      params.require(:taxonomy_node).permit(:parent_key, :name_en, :name_fr, :position)
    end

    def next_position(node)
      TaxonomyNode.where(kind: node.kind, parent_key: node.parent_key).maximum(:position).to_i + 1
    end
  end
end
