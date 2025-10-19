# frozen_string_literal: true

class Ui::GridComponentPreview < ViewComponent::Preview
  def default
    render Ui::GridComponent.new do
      safe_join([
        content_tag(:div, class: "p-4 bg-info rounded text-center") { "Item 1" },
        content_tag(:div, class: "p-4 bg-success rounded text-center") { "Item 2" },
        content_tag(:div, class: "p-4 bg-warning rounded text-center") { "Item 3" },
        content_tag(:div, class: "p-4 bg-danger rounded text-center") { "Item 4" }
      ])
    end
  end

  def fixed_columns
    render Ui::GridComponent.new(columns: 3, gap: "2rem") do
      (1..6).map do |i|
        content_tag :div, class: "p-6 bg-gray rounded-lg text-center font-semibold" do
          "Column #{i}"
        end
      end.join.html_safe
    end
  end

  def custom_spacing
    render Ui::GridComponent.new(
      gap: "0.5rem",
      min_width: "200px",
      css_class: "grid border rounded-lg p-4"
    ) do
      %w[Alpha Beta Gamma Delta Epsilon Zeta].map do |item|
        content_tag :div, class: "p-3 bg-deep-indigo rounded text-center text-sm" do
          item
        end
      end.join.html_safe
    end
  end

  def card_grid
    cards = [
      { title: "Dashboard", desc: "View your overview", color: "bg-deep-indigo" },
      { title: "Analytics", desc: "Track your metrics", color: "bg-info" },
      { title: "Settings", desc: "Configure options", color: "bg-success" },
      { title: "Profile", desc: "Manage account", color: "bg-warning" }
    ]

    render Ui::GridComponent.new(
      columns: 2,
      gap: "1.5rem",
      css_class: "grid max-w-2xl"
    ) do
      cards.map do |card|
        content_tag :div, class: "#{card[:color]} p-6 rounded-lg shadow-sm border" do
          safe_join([
            content_tag(:h3, card[:title], class: "font-semibold text-lg mb-2"),
            content_tag(:p, card[:desc], class: "text-gray text-sm")
          ])
        end
      end.join.html_safe
    end
  end

  def responsive_grid
    render Ui::GridComponent.new(
      min_width: "150px",
      gap: "1rem",
      css_class: "grid border-2 border-dashed border-gray p-4 rounded"
    ) do
      (1..12).map do |i|
        content_tag :div, class: "aspect-square bg-gradient-to-br from-pink-100 to-purple-100 rounded flex items-center justify-center font-bold text-lg" do
          i.to_s
        end
      end.join.html_safe
    end
  end

  def single_column
    items = ["Header", "Navigation", "Main Content", "Sidebar", "Footer"]

    render Ui::GridComponent.new(
      columns: 1,
      gap: "1rem",
      css_class: "grid max-w-md mx-auto"
    ) do
      items.map.with_index do |item, index|
        height_class = case item
                      when "Main Content" then "h-32"
                      when "Header", "Footer" then "h-16"
                      else "h-12"
                      end

        content_tag :div, class: "#{height_class} bg-gray-200 rounded flex items-center justify-center font-medium" do
          item
        end
      end.join.html_safe
    end
  end

  def flexible_content
    items = ["Dashboard", "Analytics", "Settings", "Profile", "Reports", "Users"]

    render Ui::GridComponent.new(
      columns: 3,
      gap: "1rem",
      css_class: "grid max-w-4xl"
    ) do
      items.map do |item|
        content_tag :div, class: "p-4 bg-gradient-to-br from-purple-100 to-pink-100 rounded-lg text-center font-semibold shadow-sm hover:shadow-md transition-shadow" do
          item
        end
      end.join.html_safe
    end
  end
end
