# frozen_string_literal: true

AffiliateTracker.configure do |config|
  # Your brand name (appears in utm_source)
  # config.utm_source = "mybrand"

  # Default medium (appears in utm_medium)
  # config.utm_medium = "email"

  # Referral param (adds ?ref=yourname to all links)
  # config.ref_param = "yourname"

  # Dashboard authentication (optional)
  # config.authenticate_dashboard = -> {
  #   redirect_to main_app.login_path unless current_user&.admin?
  # }
end
