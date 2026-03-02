# frozen_string_literal: true

require "rails_helper"

RSpec.describe OtpMailer, type: :mailer do
  let(:user) { create(:user) }

  before { user.generate_otp! }

  describe "#send_otp" do
    let(:mail) { described_class.send_otp(user) }

    it "renders the headers" do
      expect(mail.to).to eq([ user.email ])
      expect(mail.from).to eq([ "noreply@spens.me" ])
      expect(mail.subject).to eq(I18n.t("auth.mailer.otp.subject"))
    end

    it "includes the OTP code in the HTML body" do
      expect(mail.body.encoded).to include(user.otp_code)
    end

    it "includes the user's first name in the body" do
      expect(mail.body.encoded).to include(user.first_name)
    end

    it "renders both HTML and text parts" do
      expect(mail.multipart?).to be true
      expect(mail.parts.map(&:content_type)).to include(
        a_string_matching("text/html"),
        a_string_matching("text/plain")
      )
    end
  end
end
