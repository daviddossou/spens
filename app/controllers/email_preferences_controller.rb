# frozen_string_literal: true

# The lifecycle e-mails' stop link, signed, without a session.
class EmailPreferencesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :stop

  # GET shows a confirmation (mail clients prefetch links); POST unsubscribes, and is also
  # what a mail client's own "unsubscribe" button calls (List-Unsubscribe-Post).
  def unsubscribe
    @token = params[:token]
    @user = User.find_signed(@token, purpose: :lifecycle_emails)
    render layout: "auth"
  end

  def stop
    @user = User.find_signed(params[:token], purpose: :lifecycle_emails)
    if @user&.lifecycle_emails?
      @user.update!(lifecycle_emails: false)
      Analytics.track(@user, "lifecycle_emails_unsubscribed", source: "email")
    end
    @stopped = true
    render :unsubscribe, layout: "auth"
  end
end
