# == Schema Information
#
# Table name: accounts
#
#  id          :uuid             not null, primary key
#  balance     :float            default(0.0), not null
#  name        :string           not null
#  saving_goal :float            default(0.0)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :uuid             not null, indexed
#
# Indexes
#
#  index_accounts_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Account, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
