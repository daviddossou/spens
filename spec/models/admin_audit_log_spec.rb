# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminAuditLog do
  let(:admin) { create(:user, :admin) }

  it "records an action against a target" do
    user = create(:user)
    log = described_class.record_action(admin_user: admin, action: "grant_admin", target: user)

    expect(log).to be_persisted
    expect(log.target).to eq(user)
  end

  it "records an action with no target" do
    log = described_class.record_action(admin_user: admin, action: "impersonate_stop")
    expect(log.target).to be_nil
  end

  it "validates the action" do
    expect { described_class.record_action(admin_user: admin, action: "nonsense") }
      .to raise_error(ActiveRecord::RecordInvalid)
  end

  it "returns a nil target when the record has since been deleted" do
    user = create(:user)
    log = described_class.record_action(admin_user: admin, action: "grant_admin", target: user)
    user.destroy

    expect(log.reload.target).to be_nil
  end
end
