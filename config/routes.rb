# frozen_string_literal: true

AffiliateTracker::Engine.routes.draw do
  get "/:payload", to: "clicks#redirect", as: :track

  if AffiliateTracker.configuration.dashboard_enabled
    get "/dashboard", to: "dashboard#index", as: :dashboard
    get "/dashboard/clicks", to: "dashboard#clicks", as: :dashboard_clicks
    get "/dashboard/stats", to: "dashboard#stats", as: :dashboard_stats
  end
end
