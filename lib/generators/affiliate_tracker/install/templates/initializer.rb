# frozen_string_literal: true

AffiliateTracker.configure do |config|
  # Dashboard authentication (optional)
  # config.authenticate_dashboard = -> {
  #   redirect_to main_app.login_path unless current_user&.admin?
  # }

  # Custom click handler (optional)
  # config.after_click = ->(click) {
  #   # click.metadata, click.destination_url, click.clicked_at
  # }
end
