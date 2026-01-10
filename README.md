# AffiliateTracker

Click tracking for affiliates working with small e-commerce shops. Track your clicks, add UTM params, prove your value.

## Problem

```
You: "I sent you 500 clicks this month"
Shop: "Google Analytics shows only 200 visits"
You: "..."
```

## Solution

```
Your email → User clicks → AffiliateTracker counts → Redirect with UTM → Shop sees source
                              ↓
                    You have proof: 500 clicks
                    Shop sees: utm_source=yourname
```

## Features

- Click tracking with metadata (shop, campaign, etc.)
- Automatic UTM parameter injection
- Click deduplication (same IP + URL within 5s counted once)
- Built-in dashboard
- Rails 8+ / zero configuration

## Installation

```ruby
gem "affiliate_tracker", git: "https://github.com/justi-blue/affiliate_tracker"
```

```bash
rails generate affiliate_tracker:install
rails db:migrate
```

## Usage

### In Emails/Views

```erb
<%= affiliate_url "https://modago.pl/sukienka-123",
      shop: "modago",
      campaign: "weekly_digest" %>
```

**Result:**
1. Generates: `https://yourapp.com/a/eyJ...?s=abc`
2. On click, redirects to: `https://modago.pl/sukienka-123?utm_source=affiliate&utm_medium=referral&utm_campaign=weekly_digest&utm_content=modago`

### Configuration

```ruby
# config/initializers/affiliate_tracker.rb
AffiliateTracker.configure do |config|
  # Your brand name (appears in utm_source)
  config.utm_source = "smartoffers"

  # Default medium
  config.utm_medium = "email"

  # Dashboard auth
  config.authenticate_dashboard = -> {
    redirect_to main_app.login_path unless current_user&.admin?
  }
end
```

### UTM Parameters

| Parameter | Source | Example |
|-----------|--------|---------|
| `utm_source` | `config.utm_source` | `smartoffers` |
| `utm_medium` | `config.utm_medium` | `email` |
| `utm_campaign` | `campaign:` in helper | `weekly_digest` |
| `utm_content` | `shop:` in helper | `modago` |

Override defaults per-link:

```erb
<%= affiliate_url "https://shop.com",
      utm_source: "newsletter",
      utm_medium: "email",
      campaign: "black_friday" %>
```

## Dashboard

Access at `/a/dashboard`

Shows:
- Total clicks
- Clicks today/this week
- Top destinations (shops)
- Recent clicks with metadata

## For Shop Owners

Tell your partner shops:
> "All my links include UTM parameters. Check Google Analytics → Acquisition → Traffic Sources → filter by `utm_source=yourname`"

## License

MIT
