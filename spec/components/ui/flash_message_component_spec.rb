# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ui::FlashMessageComponent, type: :component do
  let(:flash_hash) { {} }
  let(:component) { described_class.new(flash_hash) }

  it_behaves_like "a rendered component" do
    let(:flash_hash) { { notice: "Success message" } }
    subject(:rendered_component) { render_inline(component) }
  end

  describe "initialization" do
    it "accepts flash hash parameter" do
      component = described_class.new({ notice: "Test message" })
      expect(component).to be_instance_of(Ui::FlashMessageComponent)
    end

    it "handles empty flash hash" do
      component = described_class.new({})
      expect(component).to be_instance_of(Ui::FlashMessageComponent)
    end
  end

  describe "flash message processing" do
    let(:flash_hash) do
      {
        notice: "Success message",
        alert: "Error message",
        warning: "Warning message",
        info: "Info message"
      }
    end

    it "processes all flash message types" do
      messages = component.send(:flash_messages)
      expect(messages.length).to eq(4)

      expect(messages.map { |m| m[:type] }).to contain_exactly(:notice, :alert, :warning, :info)
      expect(messages.map { |m| m[:message] }).to contain_exactly(
        "Success message", "Error message", "Warning message", "Info message"
      )
    end

    it "includes CSS classes for each message type" do
      messages = component.send(:flash_messages)
      messages.each do |message|
        expect(message[:classes]).to be_present
        expect(message[:classes]).to include('mb-4 p-4 border rounded-md')
      end
    end
  end

  describe "CSS class assignment" do
    context "for notice/success messages" do
      it "applies green styling" do
        classes = component.send(:classes_for_type, :notice)
        expect(classes).to include('bg-success-50', 'border-success', 'text-success')
      end

      it "applies green styling for success type" do
        classes = component.send(:classes_for_type, :success)
        expect(classes).to include('bg-success-50', 'border-success', 'text-success')
      end
    end

    context "for alert/error messages" do
      it "applies red styling" do
        classes = component.send(:classes_for_type, :alert)
        expect(classes).to include('bg-danger-50', 'border-danger', 'text-danger')
      end

      it "applies red styling for error type" do
        classes = component.send(:classes_for_type, :error)
        expect(classes).to include('bg-danger-50', 'border-danger', 'text-danger')
      end
    end

    context "for warning messages" do
      it "applies yellow styling" do
        classes = component.send(:classes_for_type, :warning)
        expect(classes).to include('bg-warning-50', 'border-warning', 'text-warning')
      end
    end

    context "for info messages" do
      it "applies blue styling" do
        classes = component.send(:classes_for_type, :info)
        expect(classes).to include('bg-info-50', 'border-info', 'text-info')
      end
    end

    context "for unknown message types" do
      it "applies default gray styling" do
        classes = component.send(:classes_for_type, :unknown)
        expect(classes).to include('bg-gray-50', 'border-gray-200', 'text-gray-800')
      end
    end
  end

  describe "icon assignment" do
    it "assigns correct icons for each message type" do
      expect(component.send(:icon_for_type, :notice)).to eq("✅")
      expect(component.send(:icon_for_type, :success)).to eq("✅")
      expect(component.send(:icon_for_type, :alert)).to eq("❌")
      expect(component.send(:icon_for_type, :error)).to eq("❌")
      expect(component.send(:icon_for_type, :warning)).to eq("⚠️")
      expect(component.send(:icon_for_type, :info)).to eq("ℹ️")
    end

    it "returns empty string for unknown types" do
      expect(component.send(:icon_for_type, :unknown)).to eq("")
    end
  end

  describe "rendering behavior" do
    context "with no messages" do
      let(:flash_hash) { {} }
      subject(:rendered) { render_inline(component) }

      it "renders without content" do
        # The component should not render any actual flash message content
        html = rendered.to_html
        expect(html).not_to include('data-flash-type')
        expect(html).not_to include('bg-success-50')
      end
    end

    context "with single message" do
      let(:flash_hash) { { notice: "Success message" } }
      subject(:rendered) { render_inline(component) }

      it "renders the message" do
        expect(rendered.to_html).to include("Success message")
      end

      it "includes the icon" do
        expect(rendered.to_html).to include("✅")
      end

      it "includes dismiss button" do
        expect(rendered.to_html).to include('×')
        expect(rendered.css('button')).to be_present
      end

      it "has correct CSS classes" do
        expect(rendered.to_html).to include('bg-success-50')
      end

      it "has data attributes" do
        expect(rendered.to_html).to include('data-flash-type="notice"')
      end
    end

    context "with multiple messages" do
      let(:flash_hash) do
        {
          notice: "Success message",
          alert: "Error message"
        }
      end
      subject(:rendered) { render_inline(component) }

      it "renders all messages" do
        html = rendered.to_html
        expect(html).to include("Success message")
        expect(html).to include("Error message")
      end

      it "renders different styling for different types" do
        html = rendered.to_html
        expect(html).to include('bg-success-50')
        expect(html).to include('bg-danger-50')
      end

      it "includes dismiss buttons for each message" do
        expect(rendered.css('button').count).to eq(2)
      end
    end

    context "with string keys in flash hash" do
      let(:flash_hash) { { "notice" => "Success message" } }
      subject(:rendered) { render_inline(component) }

      it "handles string keys correctly" do
        expect(rendered.to_html).to include("Success message")
      end
    end
  end

  describe "accessibility" do
    let(:flash_hash) { { notice: "Success message" } }
    subject(:rendered) { render_inline(component) }

    it "provides meaningful button text for screen readers" do
      # The × symbol should be accessible
      expect(rendered.css('button')).to be_present
    end

    it "uses proper semantic structure" do
      expect(rendered.css('div p')).to be_present
    end
  end
end
