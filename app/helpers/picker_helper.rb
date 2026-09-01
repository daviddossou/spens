# frozen_string_literal: true

# Builds the rows a picker layer displays (Tour 31/32). A row is what the layer
# paints — icon, label, optional secondary value — plus the raw value the form
# submits, which stays the NAME the forms already post.
module PickerHelper
  # Taxonomy names carry their emoji inside the name string. It becomes the row
  # icon rather than being repeated in the label (Tour 32b-2).
  def picker_icon_and_label(name)
    icon = name.to_s[/\A[^[:alnum:]]+/].to_s.strip
    label = name.to_s.sub(/\A[^[:alnum:]]+/, "").strip
    label.blank? ? [ nil, name.to_s ] : [ icon.presence, label ]
  end

  # Categories, grouped into what the plan already covers and everything else.
  # A space with no plan gets one alphabetical list and no headers.
  def picker_category_rows(options, planned_names: [])
    planned = planned_names.map { |n| n.to_s.downcase }.to_set
    rows = options.map do |option|
      name = option[:value] || option["value"]
      icon, label = picker_icon_and_label(name)
      { value: name, label: label, icon: icon,
        group: planned.include?(name.to_s.downcase) ? "planned" : "rest",
        aliases: [ option[:aliases], option[:personal_aliases] ].compact.join(" ") }
    end
    rows.sort_by { |r| r[:label].downcase }
  end

  # Accounts, balance descending like the Accounts page — one order everywhere
  # (Tour 32b-4). The balance column is formatted as ONE column, so a single
  # small account keeps every amount exact (Tour 32d).
  def picker_account_rows(suggestions, currency = nil, savings_first: false)
    entries = suggestions.map { |s| { name: s[:name] || s["name"], balance: (s[:balance] || s["balance"]).to_f } }
    entries.sort_by! { |e| [ savings_first && !picker_savings?(e[:name]) ? 1 : 0, -e[:balance] ] }

    labels = money_column(entries.map { |e| e[:balance] }, currency, compact: true)
    entries.each_with_index.map do |entry, i|
      icon, label = picker_icon_and_label(entry[:name])
      { value: entry[:name], label: label, icon: icon, meta: labels[i] }
    end
  end

  private

  def picker_savings?(name)
    current_space&.accounts&.any? { |a| a.name == name && a.set_aside? } || false
  end
end
