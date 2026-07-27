# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "transaction_types:sync_template_names" do
  before(:all) { Rails.application.load_tasks unless Rake::Task.task_defined?("transaction_types:sync_template_names") }

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  def run_task
    Rake::Task["transaction_types:sync_template_names"].reenable
    Rake::Task["transaction_types:sync_template_names"].invoke
  end

  it "renames a legacy template name to the current taxonomy name, leaves edited names alone" do
    legacy = create(:transaction_type, space: space, kind: "expense",
                    template_key: "public_transport",
                    name: I18n.t("transaction_type_templates.public_transport.name", locale: :fr))
    edited = create(:transaction_type, space: space, kind: "expense",
                    template_key: "moto_taxi", name: "Mes zems")

    run_task

    expect(legacy.reload.name).to eq(TransactionTaxonomy.name("public_transport", :fr))
    expect(edited.reload.name).to eq("Mes zems")
  end

  it "renames despite emoji/punctuation drift from the template file" do
    drifted = create(:transaction_type, space: space, kind: "expense",
                     template_key: "public_transport", name: "🚍 Transport public")

    run_task

    expect(drifted.reload.name).to eq(TransactionTaxonomy.name("public_transport", :fr))
  end

  it "skips when the target name already exists in the space" do
    create(:transaction_type, space: space, kind: "expense",
           name: TransactionTaxonomy.name("public_transport", :fr))
    legacy = create(:transaction_type, space: space, kind: "expense",
                    template_key: "public_transport",
                    name: I18n.t("transaction_type_templates.public_transport.name", locale: :fr))

    expect { run_task }.not_to change { legacy.reload.name }
  end
end
