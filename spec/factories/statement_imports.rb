FactoryBot.define do
  factory :statement_import do
    user
    space { user.spaces.first }
    status { "reading" }
    captures { [ Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/capture.png"), "image/png") ] }
  end
end
