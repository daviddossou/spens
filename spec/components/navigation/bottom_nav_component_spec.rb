# frozen_string_literal: true

require "rails_helper"

RSpec.describe Navigation::BottomNavComponent, type: :component do
  describe "#active?" do
    # Create Tab structs directly to test active? logic without needing route helpers
    let(:dashboard_tab) { described_class::Tab.new(key: :dashboard, label: "Dashboard", path: "/dashboard", icon: :dashboard) }
    let(:debts_tab) { described_class::Tab.new(key: :debts, label: "Debts", path: "/debts", icon: :debts) }
    let(:goals_tab) { described_class::Tab.new(key: :goals, label: "Goals", path: "/goals", icon: :goals) }
    let(:accounts_tab) { described_class::Tab.new(key: :accounts, label: "Accounts", path: "/accounts", icon: :accounts) }

    context "dashboard tab" do
      it "is active on dashboard path" do
        component = described_class.new(current_path: "/dashboard")
        expect(component.active?(dashboard_tab)).to be true
      end

      it "is not active on other paths" do
        component = described_class.new(current_path: "/debts")
        expect(component.active?(dashboard_tab)).to be false
      end
    end

    context "debts tab" do
      it "is active on debts index" do
        component = described_class.new(current_path: "/debts")
        expect(component.active?(debts_tab)).to be true
      end

      it "is active on a specific debt" do
        component = described_class.new(current_path: "/debts/1")
        expect(component.active?(debts_tab)).to be true
      end

      it "is not active on goals path" do
        component = described_class.new(current_path: "/goals")
        expect(component.active?(debts_tab)).to be false
      end
    end

    context "goals tab" do
      it "is active on goals index" do
        component = described_class.new(current_path: "/goals")
        expect(component.active?(goals_tab)).to be true
      end

      it "is active on a specific goal" do
        component = described_class.new(current_path: "/goals/42")
        expect(component.active?(goals_tab)).to be true
      end

      it "is not active on debts path" do
        component = described_class.new(current_path: "/debts")
        expect(component.active?(goals_tab)).to be false
      end
    end

    context "accounts tab" do
      it "is active on accounts index" do
        component = described_class.new(current_path: "/accounts")
        expect(component.active?(accounts_tab)).to be true
      end

      it "is active on a specific account" do
        component = described_class.new(current_path: "/accounts/5")
        expect(component.active?(accounts_tab)).to be true
      end

      it "is not active on dashboard path" do
        component = described_class.new(current_path: "/dashboard")
        expect(component.active?(accounts_tab)).to be false
      end
    end
  end

  describe "#tab_classes" do
    let(:active_tab) { described_class::Tab.new(key: :dashboard, label: "Dashboard", path: "/dashboard", icon: :dashboard) }
    let(:inactive_tab) { described_class::Tab.new(key: :debts, label: "Debts", path: "/debts", icon: :debts) }
    let(:component) { described_class.new(current_path: "/dashboard") }

    it "returns base class for inactive tab" do
      expect(component.tab_classes(inactive_tab)).to eq("bottom-nav__tab")
    end

    it "returns base and active classes for active tab" do
      expect(component.tab_classes(active_tab)).to eq("bottom-nav__tab bottom-nav__tab--active")
    end
  end

  describe "rendering" do
    it "renders the nav element with correct aria label" do
      rendered = render_inline(described_class.new(current_path: "/dashboard"))
      expect(rendered.css("nav.bottom-nav[aria-label='Main navigation']")).to be_present
    end

    it "renders four tab links" do
      rendered = render_inline(described_class.new(current_path: "/dashboard"))
      expect(rendered.css(".bottom-nav__tab").length).to eq(4)
    end

    it "renders tab labels" do
      rendered = render_inline(described_class.new(current_path: "/dashboard"))

      labels = rendered.css(".bottom-nav__label").map(&:text).map(&:strip)
      expect(labels).to include(I18n.t("navigation.bottom_nav.dashboard"))
      expect(labels).to include(I18n.t("navigation.bottom_nav.debts"))
      expect(labels).to include(I18n.t("navigation.bottom_nav.goals"))
      expect(labels).to include(I18n.t("navigation.bottom_nav.accounts"))
    end

    it "renders SVG icons for each tab" do
      rendered = render_inline(described_class.new(current_path: "/dashboard"))
      expect(rendered.css(".bottom-nav__icon").length).to eq(4)
    end

    it "marks the active tab with aria-current" do
      rendered = render_inline(described_class.new(current_path: "/dashboard"))
      active_tabs = rendered.css("[aria-current='page']")
      expect(active_tabs.length).to eq(1)
    end

    it "applies active class to the correct tab" do
      rendered = render_inline(described_class.new(current_path: "/goals"))
      active_tab = rendered.css(".bottom-nav__tab--active").first
      expect(active_tab).to be_present
      expect(active_tab.text).to include(I18n.t("navigation.bottom_nav.goals"))
    end

    it "does not apply active class to inactive tabs" do
      rendered = render_inline(described_class.new(current_path: "/dashboard"))
      inactive_tabs = rendered.css(".bottom-nav__tab:not(.bottom-nav__tab--active)")
      expect(inactive_tabs.length).to eq(3)
    end

    it "renders four distinct tabs" do
      rendered = render_inline(described_class.new(current_path: "/accounts"))
      active_tab = rendered.css(".bottom-nav__tab--active").first
      expect(active_tab).to be_present
      expect(active_tab.text).to include(I18n.t("navigation.bottom_nav.accounts"))
    end
  end
end
