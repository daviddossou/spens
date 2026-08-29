# frozen_string_literal: true

module AccountsHelper
  # Accounts always show the full amount — a total means nothing if two lines
  # can't be compared, and "145K" next to "145 000" can't. Space-delimited,
  # currency at the end, never abbreviated.
  def account_money(value)
    smart_format_money(value, current_space.currency, sign: :never, threshold: Float::INFINITY)
  end

  # "dernier mouvement aujourd'hui / hier / il y a N jours" — our own keys, since
  # the app's locales don't ship the ActionView distance-in-words translations.
  def account_last_movement(date)
    days = (Date.current - date.to_date).to_i
    case days
    when 0 then t("accounts.show.last_movement.today")
    when 1 then t("accounts.show.last_movement.yesterday")
    else t("accounts.show.last_movement.days", count: days)
    end
  end
end
