module UserHelper
  # Helper method to get localized user name
  def user_display_name(user)
    if user.first_name.present?
      "#{user.first_name} #{user.last_name}".strip
    else
      user.email
    end
  end
end
