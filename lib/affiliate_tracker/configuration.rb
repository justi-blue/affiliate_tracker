# frozen_string_literal: true

module AffiliateTracker
  class Configuration
    # Dashboard authentication proc (optional)
    attr_accessor :authenticate_dashboard

    # Custom click handler (optional)
    attr_accessor :after_click

    # Default UTM source (your brand name)
    attr_accessor :utm_source

    # Default UTM medium
    attr_accessor :utm_medium

    def initialize
      @authenticate_dashboard = nil
      @after_click = nil
      @utm_source = "affiliate"
      @utm_medium = "referral"
    end

    def base_url
      host = Rails.application.routes.default_url_options[:host]
      raise Error, "Set Rails.application.routes.default_url_options[:host]" unless host
      protocol = Rails.application.routes.default_url_options[:protocol] || "https"
      "#{protocol}://#{host}"
    end

    def secret_key
      Rails.application.key_generator.generate_key("affiliate_tracker", 32)
    end
  end
end
