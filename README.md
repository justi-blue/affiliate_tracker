# AffiliateTracker

A simple Rails engine for tracking affiliate link clicks with redirect support and monitoring dashboard.

## Features

- Generate signed tracking URLs for emails and web pages
- Track clicks with metadata (shop_id, promotion_id, campaign, etc.)
- Automatic redirect to destination URL
- Click deduplication
- Built-in dashboard for monitoring
- View helpers for Rails views and mailers
- IP anonymization for privacy

## Installation

Add to your Gemfile:

```ruby
gem "affiliate_tracker", path: "../affiliate_tracker"
# or from git:
# gem "affiliate_tracker", git: "https://github.com/yourusername/affiliate_tracker"
```

Run the installer:

```bash
rails generate affiliate_tracker:install
rails db:migrate
```

## Configuration

### Environment Variables (recommended)

```bash
AFFILIATE_TRACKER_BASE_URL=https://yourapp.com
AFFILIATE_TRACKER_SECRET_KEY=your-secret-key-min-32-chars
```

### Initializer (optional overrides)

```ruby
# config/initializers/affiliate_tracker.rb
AffiliateTracker.configure do |config|
  # Override ENV if needed
  config.base_url = "https://yourapp.com"
  config.secret_key = "your-secret-key"

  # Route path (default: "/a")
  config.route_path = "/a"

  # Dashboard authentication
  config.authenticate_dashboard = -> {
    redirect_to main_app.login_path unless current_user&.admin?
  }

  # Custom click handler
  config.after_click = ->(click) {
    if click.metadata["shop_id"]
      Shop.find(click.metadata["shop_id"]).increment!(:click_count)
    end
  }
end
```

## Usage

### In Views

```erb
<%= affiliate_link "https://shop.com", "Shop Now" %>
<%= affiliate_link "https://shop.com", "Shop Now", shop_id: 1, promotion_id: 2 %>
<%= affiliate_link "https://shop.com", class: "btn" do %>
  <span>Visit Store</span>
<% end %>
```

### In Mailers

```erb
<a href="<%= affiliate_url 'https://shop.com', campaign: 'weekly_digest', user_id: @user.id %>">
  Check out this deal!
</a>
```

### Programmatically

```ruby
# Generate a tracking URL
url = AffiliateTracker.url("https://shop.com", shop_id: 1, promo: "summer")
# => "https://yourapp.com/a/eyJhbGciO...?s=abc123"
```

## Dashboard

Access at `/a/dashboard` (or your configured route_path + /dashboard).

Shows:
- Total clicks
- Clicks today/this week
- Top destinations
- Recent clicks
- Click trends

## How It Works

1. **URL Generation**: Creates a signed URL containing Base64-encoded destination + metadata
2. **Click Tracking**: When user clicks, the engine decodes the URL, records the click, and redirects
3. **Deduplication**: Same IP + destination within 5 seconds is counted once
4. **Privacy**: IP addresses are anonymized (last octet zeroed)

## Security

Every tracking URL is cryptographically signed using HMAC-SHA256:

```
https://yourapp.com/a/eyJ1IjoiaHR0cHM6Ly9zaG9wLmNvbSIsInNob3BfaWQiOjF9?s=a1b2c3d4e5f6g7h8
                      └─────────────── payload (Base64) ───────────────┘   └── signature ──┘
```

**Payload** contains:
- `u`: destination URL
- Any metadata you passed (shop_id, promotion_id, campaign, etc.)

**Signature** (`s` parameter):
- First 16 characters of HMAC-SHA256(secret_key, payload)
- Prevents URL tampering - if anyone modifies the payload, signature verification fails
- Uses `Rails.application.secret_key_base` by default

```ruby
# What happens on click:
data = UrlGenerator.decode(payload, signature)
# If signature doesn't match → 400 Bad Request
# If valid → record click and redirect
```

## Database

The gem creates a single table:

```ruby
create_table :affiliate_tracker_clicks do |t|
  t.string :destination_url, null: false
  t.string :ip_address
  t.string :user_agent
  t.string :referer
  t.json :metadata
  t.datetime :clicked_at, null: false
  t.timestamps
end
```

## Integration with SmartOffers

```ruby
# In your initializer
AffiliateTracker.configure do |config|
  config.base_url = "https://smart-offers.polanka.ovh"

  config.after_click = ->(click) {
    if (shop_id = click.metadata["shop_id"]) && (promo_id = click.metadata["promotion_id"])
      AffiliateClick.create!(
        shop_id: shop_id,
        promotion_id: promo_id,
        user_uuid: click.metadata["user_uuid"],
        click_timestamp: click.clicked_at
      )
    end
  }
end
```

In your emails:

```erb
<%= affiliate_url promotion.shop.website_url,
      shop_id: promotion.shop_id,
      promotion_id: promotion.id,
      user_uuid: @user.uuid,
      campaign: "daily_digest" %>
```

## License

MIT
