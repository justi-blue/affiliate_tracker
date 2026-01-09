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

Edit `config/initializers/affiliate_tracker.rb`:

```ruby
AffiliateTracker.configure do |config|
  # Required: Base URL for generating links
  config.base_url = "https://yourapp.com"

  # Route path (default: "/a")
  config.route_path = "/a"

  # Dashboard authentication
  config.authenticate_dashboard = -> {
    redirect_to main_app.login_path unless current_user&.admin?
  }

  # Custom click handler
  config.after_click = ->(click) {
    # Integrate with your models
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

## Performance

**Current implementation** writes one database record per click. This is fine for moderate traffic (thousands of clicks/day).

### Optimization Strategies

For high-traffic scenarios, consider these optimizations:

#### 1. Background Jobs (Recommended First Step)

Move click recording to a background job:

```ruby
# config/initializers/affiliate_tracker.rb
AffiliateTracker.configure do |config|
  config.after_click = ->(click) {
    # Click is already saved, but you can do async processing
    ProcessClickJob.perform_later(click.id)
  }
end
```

Or modify the controller to use async recording:

```ruby
# In your app, override the controller
class ClicksController < AffiliateTracker::ClicksController
  private

  def record_click(destination_url, metadata)
    RecordClickJob.perform_later(destination_url, metadata, request_info)
  end
end
```

#### 2. Redis Counters (Fast Statistics)

Use Redis for real-time counters instead of COUNT queries:

```ruby
# config/initializers/affiliate_tracker.rb
AffiliateTracker.configure do |config|
  config.after_click = ->(click) {
    redis = Redis.current

    # Increment counters atomically
    redis.incr("clicks:total")
    redis.incr("clicks:#{Date.current}")
    redis.hincrby("clicks:by_shop", click.metadata["shop_id"], 1)
    redis.hincrby("clicks:by_destination", click.domain, 1)
  }
end
```

#### 3. Batch Inserts (High Volume)

Buffer clicks and insert in batches:

```ruby
# Using Redis as buffer
class ClickBuffer
  BATCH_SIZE = 100

  def self.add(click_data)
    Redis.current.rpush("click_buffer", click_data.to_json)
    flush if Redis.current.llen("click_buffer") >= BATCH_SIZE
  end

  def self.flush
    clicks = Redis.current.lrange("click_buffer", 0, -1)
    Redis.current.del("click_buffer")

    AffiliateTracker::Click.insert_all(
      clicks.map { |c| JSON.parse(c) }
    )
  end
end

# Run flush periodically via cron/whenever
```

#### 4. Pre-aggregated Statistics

For dashboard performance, pre-compute daily stats:

```ruby
# Migration
create_table :affiliate_tracker_daily_stats do |t|
  t.date :date, null: false
  t.string :destination_url
  t.integer :shop_id
  t.integer :click_count, default: 0
  t.index [:date, :destination_url], unique: true
end

# Update hourly via cron
AffiliateTracker::Click
  .where(clicked_at: 1.hour.ago..)
  .group(:destination_url, "DATE(clicked_at)")
  .count
  .each do |(url, date), count|
    DailyStat.upsert(
      { date: date, destination_url: url, click_count: count },
      unique_by: [:date, :destination_url]
    )
  end
```

#### 5. Database Indexes

The default migration includes indexes, but for high volume add:

```ruby
add_index :affiliate_tracker_clicks, [:destination_url, :clicked_at]
add_index :affiliate_tracker_clicks, [:clicked_at, :destination_url]
add_index :affiliate_tracker_clicks, "(metadata->>'shop_id')"  # PostgreSQL
```

### When to Optimize

| Traffic Level | Recommended Approach |
|--------------|---------------------|
| < 1K clicks/day | Default (no changes needed) |
| 1K-10K clicks/day | Background jobs |
| 10K-100K clicks/day | + Redis counters |
| > 100K clicks/day | + Batch inserts + Pre-aggregated stats |

**Rule of thumb**: Start simple, optimize when you see actual bottlenecks. Premature optimization adds complexity without proven benefit.

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
