# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin taxonomy management", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:admin) { create(:user, :admin) }
  before { sign_in admin, scope: :user }
  after { TransactionTaxonomy.reload! }

  def create_parent(key: "adm_parent", kind: "expense", **attrs)
    TaxonomyNode.create!({ key:, kind:, name_en: "Parent", name_fr: "Parent" }.merge(attrs))
  end

  it "blocks non-admins" do
    sign_in create(:user), scope: :user
    get admin_taxonomy_nodes_path
    expect(response).to redirect_to(root_path)
  end

  it "lists the tree" do
    create_parent
    get admin_taxonomy_nodes_path
    expect(response.body).to include("adm_parent")
  end

  it "creates a child with the next sibling position and writes an audit row" do
    create_parent
    expect do
      post admin_taxonomy_nodes_path, params: {
        taxonomy_node: { key: "adm_child", kind: "expense", parent_key: "adm_parent",
                         name_en: "Child", name_fr: "Enfant" }
      }
    end.to change(TaxonomyNode, :count).by(1).and change(AdminAuditLog, :count).by(1)
    expect(AdminAuditLog.last.action).to eq("create_taxonomy_node")
  end

  it "updates names but never the key" do
    node = create_parent
    patch admin_taxonomy_node_path(id: node.id), params: { taxonomy_node: { key: "hacked", name_en: "Renamed" } }
    expect(node.reload).to have_attributes(key: "adm_parent", name_en: "Renamed")
  end

  it "refuses to deactivate a protected catch-all" do
    node = create_parent(key: "other_expense")
    patch deactivate_admin_taxonomy_node_path(id: node.id)
    expect(node.reload.active).to be(true)
  end

  it "deactivates a normal node" do
    node = create_parent
    expect { patch deactivate_admin_taxonomy_node_path(id: node.id) }
      .to change { node.reload.active }.to(false)
      .and change(AdminAuditLog, :count).by(1)
  end

  it "refuses to destroy a referenced node" do
    node = create_parent
    create(:transaction_type, space: create(:space), template_key: node.key)
    expect { delete admin_taxonomy_node_path(id: node.id) }.not_to change(TaxonomyNode, :count)
  end

  it "destroys an unreferenced node" do
    node = create_parent
    expect { delete admin_taxonomy_node_path(id: node.id) }.to change(TaxonomyNode, :count).by(-1)
  end

  it "filters the tree by search and keeps matching groups open" do
    create_parent(key: "adm_food", name_en: "Food")
    create_parent(key: "adm_ride", name_en: "Rides")
    TaxonomyNode.create!(key: "adm_zem", kind: "expense", parent_key: "adm_ride", name_en: "Zem", name_fr: "Zem")

    get admin_taxonomy_nodes_path(q: "zem")
    expect(response.body).to include("adm_ride")
    expect(response.body).not_to include("adm_food")
    expect(response.body).to include("admin-taxgroup--open")
  end

  it "reorders siblings with move_down" do
    a = create_parent(key: "adm_a", position: 0)
    b = create_parent(key: "adm_b", position: 1)

    patch move_down_admin_taxonomy_node_path(id: a.id)
    expect(a.reload.position).to be > b.reload.position
  end

  it "reorders a whole sibling group from a drag-and-drop payload" do
    a = create_parent(key: "adm_a", position: 0)
    b = create_parent(key: "adm_b", position: 1)
    c = create_parent(key: "adm_c", position: 2)

    patch reorder_admin_taxonomy_nodes_path, params: { keys: %w[adm_c adm_a adm_b] }, as: :json
    expect(response).to have_http_status(:ok)
    expect([ c, a, b ].map { |n| n.reload.position }).to eq([ 0, 1, 2 ])
  end

  it "refuses a drag payload that mixes sibling groups" do
    parent = create_parent(key: "adm_p", position: 0)
    child = TaxonomyNode.create!(key: "adm_pc", kind: "expense", parent_key: "adm_p", name_en: "C", name_fr: "C")

    patch reorder_admin_taxonomy_nodes_path, params: { keys: %w[adm_p adm_pc] }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect([ parent.reload.position, child.reload.position ]).to eq([ 0, 0 ])
  end

  it "renames inline over turbo_stream" do
    node = create_parent
    patch rename_admin_taxonomy_node_path(id: node.id), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    expect(response.body).to include("taxonomy_node[name_en]")

    patch admin_taxonomy_node_path(id: node.id),
          params: { taxonomy_node: { name_en: "Renamed inline" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    expect(node.reload.name_en).to eq("Renamed inline")
    expect(response.body).to include("Renamed inline")
  end
end
