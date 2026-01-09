# frozen_string_literal: true

module AffiliateTracker
  class DashboardController < ApplicationController
    before_action :authenticate!

    def index
      @stats = {
        total_clicks: Click.count,
        today_clicks: Click.where("clicked_at >= ?", Time.current.beginning_of_day).count,
        week_clicks: Click.where("clicked_at >= ?", 1.week.ago).count,
        unique_destinations: Click.distinct.count(:destination_url)
      }

      @recent_clicks = Click.order(clicked_at: :desc).limit(20)
      @top_destinations = Click.group(:destination_url)
                               .order("count_all DESC")
                               .limit(10)
                               .count
    end

    def clicks
      @clicks = Click.order(clicked_at: :desc).page(params[:page]).per(50)
    end

    def stats
      @daily_stats = Click.where("clicked_at >= ?", 30.days.ago)
                          .group("DATE(clicked_at)")
                          .count
                          .transform_keys(&:to_s)

      respond_to do |format|
        format.html
        format.json { render json: @daily_stats }
      end
    end

    private

    def authenticate!
      if (auth = AffiliateTracker.configuration.authenticate_dashboard)
        instance_exec(&auth)
      end
    end
  end
end
