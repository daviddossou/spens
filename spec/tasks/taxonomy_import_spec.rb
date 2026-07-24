# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "taxonomy:import_nodes" do
  before(:all) { Rails.application.load_tasks unless Rake::Task.task_defined?("taxonomy:import_nodes") }
  after { TransactionTaxonomy.reload! }

  def run_task
    Rake::Task["taxonomy:import_nodes"].reenable
    Rake::Task["taxonomy:import_nodes"].invoke
  end

  it "seeds the YML tree once and never touches existing rows again" do
    expect { run_task }.to change(TaxonomyNode, :count).from(0)
    count = TaxonomyNode.count

    groceries = TaxonomyNode.find_by!(key: "groceries")
    groceries.update!(name_fr: "Mes courses")

    expect { run_task }.not_to change(TaxonomyNode, :count)
    expect(groceries.reload.name_fr).to eq("Mes courses")
    expect(TaxonomyNode.count).to eq(count)
  end

  it "preserves YML ordering via position" do
    run_task
    yml_parents = YAML.load_file(TransactionTaxonomy::PATH)["expense"].keys
    expect(TransactionTaxonomy.parent_keys("expense")).to eq(yml_parents)
  end
end
