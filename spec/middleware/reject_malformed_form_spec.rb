# frozen_string_literal: true

require "rails_helper"

RSpec.describe Middleware::RejectMalformedForm, type: :request do
  it "answers 400 to a multipart part tagged with a UTF-16 charset" do
    body = [
      "--b", "Content-Disposition: form-data; name=\"a[b]\"", "Content-Type: text/plain; charset=utf-16le", "", "x", "--b--", ""
    ].join("\r\n")

    post "/users/sign_in", params: body, headers: { "CONTENT_TYPE" => "multipart/form-data; boundary=b" }

    expect(response).to have_http_status(:bad_request)
  end
end
