# frozen_string_literal: true

class Navigation::BottomNavComponent < ViewComponent::Base
  Tab = Struct.new(:key, :label, :path, :icon, keyword_init: true)

  attr_reader :current_path

  def initialize(current_path: "/")
    @current_path = current_path
  end

  def tabs
    @tabs ||= [
      Tab.new(key: :dashboard, label: t("navigation.bottom_nav.dashboard"), path: helpers.dashboard_path, icon: :dashboard),
      Tab.new(key: :debts, label: t("navigation.bottom_nav.debts"), path: helpers.debts_path, icon: :debts),
      Tab.new(key: :goals, label: t("navigation.bottom_nav.goals"), path: helpers.goals_path, icon: :goals),
      Tab.new(key: :accounts, label: t("navigation.bottom_nav.accounts"), path: helpers.accounts_path, icon: :accounts)
    ]
  end

  def active?(tab)
    case tab.key
    when :dashboard
      current_path == "/" || current_path.match?(%r{/dashboard\b})
    when :debts
      current_path.match?(%r{/debts\b})
    when :goals
      current_path.match?(%r{/goals\b})
    when :accounts
      current_path.match?(%r{/accounts\b})
    else
      false
    end
  end

  def tab_classes(tab)
    base = "bottom-nav__tab"
    active?(tab) ? "#{base} bottom-nav__tab--active" : base
  end
end
