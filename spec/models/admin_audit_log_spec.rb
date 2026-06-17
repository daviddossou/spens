# frozen_string_literal: true

# == Schema Information
#
# Table name: admin_audit_logs
#
#  id            :uuid             not null, primary key
#  action        :string           not null, indexed
#  metadata      :jsonb            not null
#  target_type   :string           indexed => [target_id]
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  admin_user_id :uuid             not null, indexed
#  target_id     :uuid             indexed => [target_type]
#
# Indexes
#
#  index_admin_audit_logs_on_action                     (action)
#  index_admin_audit_logs_on_admin_user_id              (admin_user_id)
#  index_admin_audit_logs_on_target_type_and_target_id  (target_type,target_id)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => users.id)
#
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
