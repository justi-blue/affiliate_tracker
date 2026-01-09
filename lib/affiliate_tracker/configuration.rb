# frozen_string_literal: true

module AffiliateTracker
  class Configuration
    # Base URL for generating tracking links (e.g., "https://yourapp.com")
    attr_accessor :base_url

    # Route path for the tracking endpoint (default: "/a")
    attr_accessor :route_path

    # Secret key for signing URLs (prevents tampering)
    attr_accessor :secret_key

    # Enable/disable dashboard (default: true)
    attr_accessor :dashboard_enabled

    # Dashboard authentication proc (receives controller instance)
    attr_accessor :authenticate_dashboard

    # Custom click handler (receives Click record after save)
    attr_accessor :after_click

    # Time window for click deduplication in seconds (default: 5)
    attr_accessor :dedup_window

    def initialize
      @base_url = nil
      @route_path = "/a"
      @secret_key = nil
      @dashboard_enabled = true
      @authenticate_dashboard = nil
      @after_click = nil
      @dedup_window = 5
    end

    def base_url
      @base_url || (defined?(Rails) ? Rails.application.routes.default_url_options[:host] : nil)
    end

    def secret_key
      @secret_key || (defined?(Rails) ? Rails.application.secret_key_base&.first(32) : nil)
    end
  end
end
