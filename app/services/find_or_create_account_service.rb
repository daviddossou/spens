# frozen_string_literal: true

class FindOrCreateAccountService
  def initialize(space, account_name)
    @space = space
    @account_name = account_name
  end

  def call
    @space.accounts.find_or_create_by!(name: @account_name.strip) do |account|
      account.balance = 0.0
      account.saving_goal = 0.0
    end
  end
end
