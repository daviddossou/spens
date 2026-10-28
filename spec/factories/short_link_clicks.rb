# == Schema Information
#
# Table name: short_link_clicks
#
#  id         :uuid             not null, primary key
#  campaign   :string
#  code       :string           not null, indexed
#  referer    :string
#  user_agent :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid             indexed
#
# Indexes
#
#  index_short_link_clicks_on_code     (code)
#  index_short_link_clicks_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :short_link_click do
    code { "1" }
    campaign { "cohorte-nov" }
    user_agent { "Mozilla/5.0" }
    referer { nil }
    user { nil }
  end
end
