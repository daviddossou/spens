# frozen_string_literal: true

class OtpMailer < ApplicationMailer
  def send_otp(user)
    @user = user
    @otp_code = user.otp_code

    mail(to: @user.email, subject: t("auth.mailer.otp.subject"))
  end
end
