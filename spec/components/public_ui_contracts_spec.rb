# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public UI component contracts", type: :component do
  def builder(name = "record", object = nil)
    ActionView::Helpers::FormBuilder.new(name, object, vc_test_controller.view_context, {})
  end

  it "preserves a custom OTP name, label association and autocomplete on a model-less builder" do
    rendered = render_inline(Forms::InputFieldComponent.new(
      form: builder, field: :code, name: "otp_code", id: "otp_code", label: "Code",
      autocomplete: "one-time-code", inputmode: "numeric", maxlength: 6,
      field_data: { otp_input_target: "input", action: "input->otp-input#handleInput" }
    ))
    expect(rendered.at_css('label[for="otp_code"]')).to be_present
    input = rendered.at_css('input[name="otp_code"]')
    expect(input["autocomplete"]).to eq("one-time-code")
    expect(input["data-otp-input-target"]).to eq("input")
    expect(input["maxlength"]).to eq("6")
  end

  it "preserves nested date names without a form builder" do
    rendered = render_inline(Forms::InputFieldComponent.new(
      field: "budget_item[ends_on]", type: :date_field, bare: true, value: Date.new(2027, 2, 3),
      aria: { label: "Fin" }, data: { budget_line_target: "endInput" }
    ))
    input = rendered.at_css('input[type="date"]')
    expect(input["name"]).to eq("budget_item[ends_on]")
    expect(input["value"]).to eq("2027-02-03")
    expect(input["data-budget-line-target"]).to eq("endInput")
  end

  it "renders grouped choices and keeps their selected value on a model-less builder" do
    rendered = render_inline(Forms::SelectFieldComponent.new(
      form: builder, field: :taxonomy_key, grouped: true, bare: true, searchable: true,
      options: [ [ "Food", [ [ "Rice", "rice" ], [ "Bread", "bread" ] ] ] ], selected: "bread",
      onchange: "this.form.requestSubmit()"
    ))
    expect(rendered.at_css('optgroup[label="Food"] option[selected]')["value"]).to eq("bread")
    expect(rendered.at_css("select")["data-controller"]).to eq("searchable-select")
    expect(rendered.at_css("select")["onchange"]).to eq("this.form.requestSubmit()")
  end

  it "keeps false as an actual selected native radio value" do
    rendered = render_inline(Ui::SelectableCardComponent.new(
      item: { value: false, name: "Confort", description: "Adjustable" }, native_radio: true,
      field: "budget_item[essential]", selected: true, css_class: "vc-card",
      input_options: { class: "vc-card__input" }
    ))
    expect(rendered.at_css('input[type="radio"][checked]')["value"]).to eq("false")
    expect(rendered.css('[data-controller="ui--selectable-card"]')).to be_empty
  end

  it "submits an unchecked toggle as zero and only includes the example when requested" do
    rendered = render_inline(Forms::ToggleFieldComponent.new(
      name: "budget_item[rollover]", checked: false, label: "Report",
      data: { budget_line_target: "rollover" }
    ))
    expect(rendered.at_css('input[type="hidden"]')["value"]).to eq("0")
    expect(rendered.at_css('input[type="checkbox"]')["value"]).to eq("1")
    expect(rendered.css('input[checked], .budget-toggle__sub')).to be_empty
  end

  it "retains the recurrence targets and namespace in the open monthly editor" do
    rendered = render_inline(Budgets::RecurrenceFieldsComponent.new(
      frequency: "quarterly", ends_on: Date.new(2027, 1, 1), rollover: true,
      expense: true, open: true, show_example: false
    ))
    expect(rendered.at_css("details[open]")).to be_present
    expect(rendered.at_css('input[data-budget-line-target="frequency"]')["name"]).to eq("budget_item[frequency]")
    expect(rendered.at_css('.seg--active')["data-frequency"]).to eq("quarterly")
    expect(rendered.at_css('.pill--active')["data-end"]).to eq("date")
    expect(rendered.css('.budget-setting__date.hidden')).to be_empty
    expect(rendered.at_css('input[type="checkbox"][checked]')).to be_present
  end

  it "retains the disabled state and tab semantics without creating a navigable link" do
    rendered = render_inline(Ui::SwitcherComponent.new(
      current: :plan, option_role: "tab", options: [
        { value: :plan, text: "Plan", url: "/plan" },
        { value: :live, text: "Live", url: "/live", disabled: true }
      ]
    ))
    expect(rendered.at_css('a[aria-selected="true"]')["href"]).to eq("/plan")
    expect(rendered.at_css('span[aria-disabled="true"]')).to be_present
    expect(rendered.css('a[href="/live"]')).to be_empty
  end

  it "bounds the visual gauge without losing its overrun description" do
    rendered = render_inline(Ui::ProgressBarComponent.new(percentage: 140, label: "Food: 140%"))
    expect(rendered.at_css('[role="progressbar"]')["aria-valuenow"]).to eq("100")
    expect(rendered.at_css('[role="progressbar"]')["aria-label"]).to eq("Food: 140%")
    expect(rendered.at_css('.progress-fill')["style"]).to eq("width: 100%;")
  end

  it "renders a custom action-menu trigger and preserves action methods and confirmation" do
    rendered = render_inline(Ui::ActionMenuComponent.new(label: "Actions")) do |menu|
      menu.with_trigger { "September" }
      vc_test_controller.view_context.link_to("Archive", "/archive", data: { turbo_method: :post, turbo_confirm: "Sure?" })
    end
    expect(rendered.at_css("summary").text.strip).to eq("September")
    expect(rendered.at_css('a[data-turbo-method="post"]')["data-turbo-confirm"]).to eq("Sure?")
  end

  it "keeps marketing button attributes without introducing application button classes" do
    rendered = render_inline(Ui::ButtonComponent.new(url: "/guide.pdf", text: "Download", styled: false,
      classes: "landing-btn-light", download: "Guide.pdf", data: { action: "download#start" }))
    expect(rendered.at_css("a")["class"]).to eq("landing-btn-light")
    expect(rendered.at_css("a")["download"]).to eq("Guide.pdf")
  end

  it "renders static facts without misleading edit affordances" do
    rendered = render_inline(Transactions::FactRowComponent.new(label: "Category", value: "Transfer"))
    expect(rendered.at_css('.movement-facts__row--static')).to be_present
    expect(rendered.css('a, .movement-facts__chevron')).to be_empty
  end
end
