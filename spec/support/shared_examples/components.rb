# frozen_string_literal: true

# Shared examples for ViewComponents
RSpec.shared_examples "a rendered component" do
  it "renders without errors" do
    expect { rendered_component }.not_to raise_error
  end

  it "returns HTML content" do
    expect(rendered_component).to be_present
    expect(rendered_component.to_html).to be_a(String)
  end
end

RSpec.shared_examples "a component with CSS classes" do |expected_classes|
  it "includes expected CSS classes" do
    html_content = rendered_component.to_html
    expected_classes.each do |css_class|
      expect(html_content).to include(css_class)
    end
  end
end

RSpec.shared_examples "a form component" do
  it "renders form elements correctly" do
    html_content = rendered_component.to_html
    expect(html_content).to match(/<input|<select|<textarea|<label/)
  end
end

RSpec.shared_examples "an accessible component" do
  it "has proper accessibility attributes" do
    # This is a placeholder for accessibility testing
    # In a real app, you might use axe-rspec or similar tools
    expect(rendered_component).to be_present
  end
end
