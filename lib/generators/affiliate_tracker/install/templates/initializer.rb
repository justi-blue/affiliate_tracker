# frozen_string_literal: true

AffiliateTracker.configure do |config|
  # Base URL for generating tracking links
  # config.base_url = "https://yourapp.com"

  # Route path for the tracking endpoint (default: "/a")
  # config.route_path = "/a"

  # Secret key for signing URLs (defaults to Rails secret_key_base)
  # config.secret_key = Rails.application.secret_key_base.first(32)

  # Enable/disable dashboard (default: true)
  # config.dashboard_enabled = true

  # Dashboard authentication (optional)
  # config.authenticate_dashboard = -> {
  #   redirect_to main_app.login_path unless current_user&.admin?
  # }

  # Custom click handler (optional)
  # config.after_click = ->(click) {
  #   # Log to analytics, update counters, etc.
  #   Analytics.track("affiliate_click", click.metadata)
  # }

  # Time window for click deduplication in seconds (default: 5)
  # config.dedup_window = 5
end
