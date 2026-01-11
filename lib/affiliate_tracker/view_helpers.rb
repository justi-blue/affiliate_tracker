# frozen_string_literal: true

module AffiliateTracker
  module ViewHelpers
    # Generate a trackable affiliate link
    #
    # @param url [String] Destination URL
    # @param text [String] Link text
    # @param options [Hash] Tracking metadata (stored in click record)
    #
    # Common tracking options:
    #   user_id:      - ID of user who will click (for attribution)
    #   shop_id:      - Shop/store identifier
    #   promotion_id: - Specific promotion being clicked
    #   campaign:     - Campaign name (e.g., "daily_digest", "weekly_email")
    #
    # HTML options (applied to <a> tag, not stored):
    #   class:, id:, style:, target:, rel:
    #
    # Examples:
    #   # Basic link
    #   affiliate_link("https://shop.com", "Shop Now")
    #
    #   # With user tracking (recommended for emails)
    #   affiliate_link("https://shop.com", "Shop Now", user_id: @user.id, campaign: "email")
    #
    #   # Full tracking
    #   affiliate_link("https://shop.com", "View Deal",
    #     user_id: @user.id,
    #     shop_id: @shop.id,
    #     promotion_id: @promotion.id,
    #     campaign: "daily_digest")
    #
    #   # With block
    #   affiliate_link("https://shop.com", user_id: @user.id) { "Shop Now" }
    #
    def affiliate_link(url, text_or_options = nil, options = {}, html_options = {}, &block)
      if block_given?
        options = text_or_options || {}
        text = capture(&block)
      else
        text = text_or_options
      end

      html_keys = [:class, :id, :style, :target, :rel]
      tracking_url = AffiliateTracker.url(url, **options.except(*html_keys))
      html_opts = { href: tracking_url, target: "_blank", rel: "noopener" }
      html_opts.merge!(html_options)
      html_opts.merge!(options.slice(*html_keys))

      content_tag(:a, text, html_opts)
    end

    # Generate just the tracking URL (useful for emails or manual links)
    #
    # @param url [String] Destination URL
    # @param metadata [Hash] Tracking data (see affiliate_link for common options)
    #
    # Examples:
    #   affiliate_url("https://shop.com")
    #   affiliate_url("https://shop.com", user_id: @user.id, campaign: "email_weekly")
    #
    def affiliate_url(url, **metadata)
      AffiliateTracker.url(url, **metadata)
    end
  end
end
