# frozen_string_literal: true

# == Schema Information
#
# Table name: memberships
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  space_id   :uuid             not null, indexed, indexed => [user_id]
#  user_id    :uuid             not null, indexed, indexed => [space_id]
#
# Indexes
#
#  index_memberships_on_space_id              (space_id)
#  index_memberships_on_user_id               (user_id)
#  index_memberships_on_user_id_and_space_id  (user_id,space_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (space_id => spaces.id)
#  fk_rails_...  (user_id => users.id)
#
class Membership < ApplicationRecord
  ##
  # Associations
  belongs_to :user
  belongs_to :space

  ##
  # Validations
  validates :user_id, uniqueness: { scope: :space_id }
end
