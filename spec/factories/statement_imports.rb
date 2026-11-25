# == Schema Information
#
# Table name: statement_imports
#
#  id         :uuid             not null, primary key
#  error      :text
#  model      :string
#  reads      :jsonb            not null
#  saved_at   :datetime
#  source     :string
#  status     :string           default("draft"), not null, indexed
#  undone_at  :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :uuid             indexed
#  space_id   :uuid             not null, indexed
#  user_id    :uuid             not null, indexed
#
# Indexes
#
#  index_statement_imports_on_account_id  (account_id)
#  index_statement_imports_on_space_id    (space_id)
#  index_statement_imports_on_status      (status)
#  index_statement_imports_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => nullify
#  fk_rails_...  (space_id => spaces.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :statement_import do
    user
    space { user.spaces.first }
    status { "reading" }
    captures { [ Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/capture.png"), "image/png") ] }
  end
end
