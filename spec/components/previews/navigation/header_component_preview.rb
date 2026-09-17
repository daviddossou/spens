# frozen_string_literal: true

module Navigation
  # @label App Header
  class HeaderComponentPreview < ViewComponent::Preview
    # Title, initials and the space name
    def default
      render(Navigation::HeaderComponent.new(page_title: "Dashboard", current_user: user, current_space: space))
    end

    # No space: no space link, no learned-words item
    def without_space
      render(Navigation::HeaderComponent.new(page_title: "Spaces", current_user: user))
    end

    # No names: the avatar falls back to the email's first letter
    def email_only_user
      render(Navigation::HeaderComponent.new(page_title: "Dashboard", current_user: User.new(email: "awa@example.com"), current_space: space))
    end

    # Admin user sees the admin item
    def admin_user
      render(Navigation::HeaderComponent.new(page_title: "Dashboard", current_user: user(admin: true), current_space: space))
    end

    private

    def user(admin: false)
      User.new(first_name: "Awa", last_name: "Diallo", email: "awa@example.com", admin: admin)
    end

    def space
      Space.new(id: SecureRandom.uuid, name: "Personal", currency: "XOF")
    end
  end
end
