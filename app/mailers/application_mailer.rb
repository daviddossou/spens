class ApplicationMailer < ActionMailer::Base
  # Replies to any app email land in the support inbox (contact@ is forwarded, see DNS).
  default from: "Spens <noreply@spens.me>", reply_to: "Spens <contact@spens.me>"
  layout "mailer"
end
