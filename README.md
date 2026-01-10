# AffiliateTracker

Simple affiliate link tracking for Rails 8+. Zero configuration required.

## Features

- Signed tracking URLs (HMAC-SHA256)
- Click tracking with metadata
- Click deduplication (same IP + URL within 5s counted once)
- Automatic redirect to destination
- Built-in dashboard
- View helpers for views and mailers

## Requirements

- Rails 8.0+
- `default_url_options[:host]` configured

## Installation

```ruby
gem "affiliate_tracker", git: "https://github.com/justi-blue/affiliate_tracker"
```

```bash
rails generate affiliate_tracker:install
rails db:migrate
```

Mount in `config/routes.rb`:

```ruby
mount AffiliateTracker::Engine, at: "/a"
```

## Usage

### In Views/Mailers

```erb
<%= affiliate_link "https://shop.com", "Shop Now" %>
<%= affiliate_link "https://shop.com", "Shop Now", shop_id: 1, promo_id: 2 %>

<a href="<%= affiliate_url 'https://shop.com', campaign: 'email' %>">Visit</a>
```

### Programmatically

```ruby
AffiliateTracker.url("https://shop.com", shop_id: 1)
# => "https://yourapp.com/a/eyJ1Ijoi...?s=abc123"
```

## Configuration (optional)

```ruby
# config/initializers/affiliate_tracker.rb
AffiliateTracker.configure do |config|
  # Dashboard authentication
  config.authenticate_dashboard = -> {
    redirect_to main_app.login_path unless current_user&.admin?
  }

  # Custom click handler
  config.after_click = ->(click) {
    Analytics.track("click", click.metadata)
  }
end
```

## Dashboard

Access at `/a/dashboard`

## How It Works

1. `affiliate_url` generates signed URL with Base64 payload
2. User clicks → gem records click → redirects to destination
3. Signature derived from `Rails.application.key_generator` (no separate secret needed)
4. Base URL from `Rails.application.routes.default_url_options[:host]`

## License

MIT
