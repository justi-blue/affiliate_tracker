# frozen_string_literal: true

AffiliateTracker::Engine.routes.draw do
  get "/:payload", to: "clicks#redirect", as: :track
  get "/dashboard", to: "dashboard#index", as: :dashboard
end
