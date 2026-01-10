# frozen_string_literal: true

module AffiliateTracker
  class Click < ActiveRecord::Base
    self.table_name = "affiliate_tracker_clicks"

    validates :destination_url, presence: true
    validates :clicked_at, presence: true

    # metadata is native JSON column - no serialize needed in Rails 8

    scope :today, -> { where("clicked_at >= ?", Time.current.beginning_of_day) }
    scope :this_week, -> { where("clicked_at >= ?", 1.week.ago) }
    scope :this_month, -> { where("clicked_at >= ?", 1.month.ago) }

    def domain
      URI.parse(destination_url).host
    rescue URI::InvalidURIError
      nil
    end
  end
end
