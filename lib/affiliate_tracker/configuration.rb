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

    # Referral parameter (e.g., "partnerJan" adds ?ref=partnerJan)
    attr_accessor :ref_param

    def initialize
      @authenticate_dashboard = nil
      @after_click = nil
      @utm_source = "affiliate"
      @utm_medium = "referral"
      @ref_param = nil
    end

    def base_url
      # Try routes first, then ActionMailer::Base as fallback (Rails 8 way)
      options = Rails.application.routes.default_url_options.presence ||
                ActionMailer::Base.default_url_options.presence ||
                {}

      host = options[:host]
      raise Error, "Set config.action_mailer.default_url_options = { host: 'example.com' } in config/environments/*.rb" unless host

      protocol = options[:protocol] || "https"
      "#{protocol}://#{host}"
    end

    def secret_key
      Rails.application.key_generator.generate_key("affiliate_tracker", 32)
    end
  end
end
