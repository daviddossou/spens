# frozen_string_literal: true

require "rails_helper"

RSpec.describe Forms::FieldHeadingComponent, type: :component do
  it "renders the label and the hint side by side" do
    rendered = render_inline(described_class.new) do |heading|
      heading.with_label { '<span class="form-label">Note</span>'.html_safe }
      heading.with_hint { '<span class="tx-detail__hint">Optional</span>'.html_safe }
    end
    head = rendered.at_css(".tx-detail__head")
    expect(head.at_css(".form-label").text).to eq("Note")
    expect(head.at_css(".tx-detail__hint").text).to eq("Optional")
  end

  it "renders only the label without a hint" do
    rendered = render_inline(described_class.new) do |heading|
      heading.with_label { '<span class="form-label">Deadline</span>'.html_safe }
    end
    expect(rendered.at_css(".tx-detail__head .form-label").text).to eq("Deadline")
    expect(rendered.css(".tx-detail__hint")).to be_empty
  end
end
