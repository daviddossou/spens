# == Schema Information
#
# Table name: debts
#
#  id               :uuid             not null, primary key
#  direction        :string           default("lent"), not null
#  name             :string           not null
#  note             :text
#  status           :string           default("ongoing"), not null, indexed
#  total_lent       :float            default(0.0), not null
#  total_reimbursed :float            default(0.0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :uuid             not null, indexed
#
# Indexes
#
#  index_debts_on_status   (status)
#  index_debts_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Debt, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
