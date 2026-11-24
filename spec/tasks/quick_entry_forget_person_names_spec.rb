# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "quick_entry:forget_person_names" do
  before(:all) { Rails.application.load_tasks unless Rake::Task.task_defined?("quick_entry:forget_person_names") }

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  def run_task
    Rake::Task["quick_entry:forget_person_names"].reenable
    Rake::Task["quick_entry:forget_person_names"].invoke
  end

  it "forgets a person's name learned as a keyword, keeps real verbs" do
    create(:debt, space: space, name: "Doris", direction: "borrowed")
    LearnedKeyword.personal_teach(space: space, phrase: "doris", kind: "debt_in")
    LearnedKeyword.personal_teach(space: space, phrase: "depanne", kind: "debt_out")

    expect { run_task }.to output(/removed: 1/).to_stdout

    expect(LearnedKeyword.personal_index(space)).to eq("depanne" => "debt_out")
  end
end
