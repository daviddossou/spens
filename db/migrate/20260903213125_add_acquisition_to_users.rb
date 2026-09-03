class AddAcquisitionToUsers < ActiveRecord::Migration[7.1]
  def change
    # First-touch attribution (utm_*, fbclid, guide_link) + marketing consent,
    # captured in session on first visit and attached at registration.
    add_column :users, :acquisition, :jsonb, default: {}, null: false
  end
end
