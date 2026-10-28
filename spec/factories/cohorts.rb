# == Schema Information
#
# Table name: cohorts
#
#  id                   :uuid             not null, primary key
#  active               :boolean          default(FALSE), not null
#  campaign             :string           not null, indexed
#  registrations_closed :boolean          default(FALSE), not null
#  whatsapp_group_url   :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_cohorts_on_campaign  (campaign) UNIQUE
#
FactoryBot.define do
  factory :cohort do
    sequence(:campaign) { |n| "cohorte-#{n}" }
    active { true }
    whatsapp_group_url { "https://chat.whatsapp.com/ABCDEF" }
  end
end
