# frozen_string_literal: true

require "rails_helper"

RSpec.describe Navigation::HeaderComponent, type: :component do
  let(:user) { create(:user, first_name: "John", last_name: "Doe", email: "john@example.com") }
  let(:page_title) { "Dashboard" }
  let(:params) { {} }

  subject(:component) do
    described_class.new(page_title: page_title, current_user: user, params: params)
  end

  describe "#user_initials" do
    it "returns uppercase initials from first and last name" do
      expect(component.user_initials).to eq("JD")
    end

    context "when user has empty last name" do
      let(:user) { build_stubbed(:user, first_name: "John", last_name: "") }

      it "returns first initial only" do
        expect(component.user_initials).to eq("J")
      end
    end

    context "when user has empty first name" do
      let(:user) { build_stubbed(:user, first_name: "", last_name: "Doe") }

      it "returns last initial only" do
        expect(component.user_initials).to eq("D")
      end
    end

    context "when user has no names" do
      let(:user) { build_stubbed(:user, first_name: "", last_name: "") }

      it "returns fallback character" do
        expect(component.user_initials).to eq("?")
      end
    end

    context "when user has lowercase names" do
      let(:user) { build_stubbed(:user, first_name: "alice", last_name: "smith") }

      it "returns uppercase initials" do
        expect(component.user_initials).to eq("AS")
      end
    end
  end

  describe "#user_full_name" do
    it "returns the display name from UserHelper" do
      expect(component.user_full_name).to eq("John Doe")
    end
  end

  describe "#user_email" do
    it "returns the user's email" do
      expect(component.user_email).to eq("john@example.com")
    end
  end

  describe "rendering" do
    before do
      # Stub LanguageSwitcherComponent to avoid route generation errors in test
      allow_any_instance_of(Navigation::LanguageSwitcherComponent)
        .to receive(:render_in).and_return("".html_safe)
    end

    it "renders the header element" do
      rendered = render_inline(component)
      expect(rendered.css("header.app-header")).to be_present
    end

    it "renders the user initials in the avatar button" do
      rendered = render_inline(component)
      expect(rendered.css(".app-header__avatar").text.strip).to eq("JD")
    end

    it "renders the page title" do
      rendered = render_inline(component)
      expect(rendered.css(".app-header__title").text.strip).to eq("Dashboard")
    end

    context "with a different page title" do
      let(:page_title) { "My Goals" }

      it "renders the correct page title" do
        rendered = render_inline(component)
        expect(rendered.css(".app-header__title").text.strip).to eq("My Goals")
      end
    end

    context "with nil page title" do
      let(:page_title) { nil }

      it "renders an empty title" do
        rendered = render_inline(component)
        expect(rendered.css(".app-header__title").text.strip).to eq("")
      end
    end

    describe "dropdown menu" do
      it "renders the user full name" do
        rendered = render_inline(component)
        expect(rendered.css(".app-header__dropdown-name").text.strip).to eq("John Doe")
      end

      it "renders the user email" do
        rendered = render_inline(component)
        expect(rendered.css(".app-header__dropdown-email").text.strip).to eq("john@example.com")
      end

      it "renders a settings link" do
        rendered = render_inline(component)
        settings_link = rendered.css("a.app-header__dropdown-item").first
        expect(settings_link).to be_present
        expect(settings_link.text).to include(I18n.t("navigation.header.settings"))
      end

      it "renders the contact support item as disabled" do
        rendered = render_inline(component)
        disabled_item = rendered.css(".app-header__dropdown-item--disabled").first
        expect(disabled_item).to be_present
        expect(disabled_item.text).to include(I18n.t("navigation.header.contact_support"))
      end

      it "renders a log out link" do
        rendered = render_inline(component)
        logout_link = rendered.css(".app-header__dropdown-item--danger").first
        expect(logout_link).to be_present
        expect(logout_link.text).to include(I18n.t("navigation.header.log_out"))
      end

      it "renders the dropdown with navigation role" do
        rendered = render_inline(component)
        expect(rendered.css("nav.app-header__dropdown[role='menu']")).to be_present
      end

      it "renders menu items with menuitem role" do
        rendered = render_inline(component)
        expect(rendered.css("[role='menuitem']").length).to be >= 3
      end

      it "renders the language switcher" do
        rendered = render_inline(component)
        expect(rendered.css(".app-header__dropdown-language")).to be_present
      end
    end

    describe "stimulus controller" do
      it "attaches the profile menu controller" do
        rendered = render_inline(component)
        expect(rendered.css("[data-controller='navigation--profile-menu']")).to be_present
      end

      it "attaches the toggle action to the avatar button" do
        rendered = render_inline(component)
        expect(rendered.css("[data-action='click->navigation--profile-menu#toggle']")).to be_present
      end

      it "has a menu target" do
        rendered = render_inline(component)
        expect(rendered.css("[data-navigation--profile-menu-target='menu']")).to be_present
      end

      it "has a backdrop target" do
        rendered = render_inline(component)
        expect(rendered.css("[data-navigation--profile-menu-target='backdrop']")).to be_present
      end
    end

    describe "right section" do
      it "renders the right section container" do
        rendered = render_inline(component)
        expect(rendered.css(".app-header__right")).to be_present
      end

      it "renders the analytics link" do
        rendered = render_inline(component)
        expect(rendered.css(".app-header__analytics-link")).to be_present
      end

      it "renders the analytics icon SVG" do
        rendered = render_inline(component)
        expect(rendered.css(".app-header__analytics-icon")).to be_present
      end
    end
  end
end
