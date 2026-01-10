# frozen_string_literal: true

module AffiliateTracker
  module ViewHelpers
    # Generate a trackable affiliate link
    #
    # Examples:
    #   affiliate_link("https://shop.com", "Shop Now")
    #   affiliate_link("https://shop.com", "Shop Now", shop_id: 1, promotion_id: 2)
    #   affiliate_link("https://shop.com", shop_id: 1) { "Shop Now" }
    #
    def affiliate_link(url, text_or_options = nil, options = {}, html_options = {}, &block)
      if block_given?
        options = text_or_options || {}
        text = capture(&block)
      else
        text = text_or_options
        options = options
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
    # Examples:
    #   affiliate_url("https://shop.com")
    #   affiliate_url("https://shop.com", shop_id: 1, campaign: "email_weekly")
    #
    def affiliate_url(url, **metadata)
      AffiliateTracker.url(url, **metadata)
    end
  end
end
