# frozen_string_literal: true

class CreateAffiliateTrackerClicks < ActiveRecord::Migration[7.0]
  def change
    create_table :affiliate_tracker_clicks do |t|
      t.string :destination_url, null: false
      t.string :ip_address
      t.string :user_agent
      t.string :referer
      t.json :metadata
      t.datetime :clicked_at, null: false

      t.timestamps
    end

    add_index :affiliate_tracker_clicks, :destination_url
    add_index :affiliate_tracker_clicks, :clicked_at
    add_index :affiliate_tracker_clicks, :created_at
  end
end
