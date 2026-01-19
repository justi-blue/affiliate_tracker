# frozen_string_literal: true

AffiliateTracker::Engine.routes.draw do
  get "/dashboard", to: "dashboard#index", as: :dashboard
  get "/:payload", to: "clicks#redirect", as: :track
end
