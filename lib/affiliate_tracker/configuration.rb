# frozen_string_literal: true

module AffiliateTracker
  class Configuration
    # Route path for the tracking endpoint (default: "/a")
    attr_accessor :route_path

    # Enable/disable dashboard (default: true)
    attr_accessor :dashboard_enabled

    # Dashboard authentication proc (receives controller instance)
    attr_accessor :authenticate_dashboard

    # Custom click handler (receives Click record after save)
    attr_accessor :after_click

    # Time window for click deduplication in seconds (default: 5)
    attr_accessor :dedup_window

    # Writers for base_url and secret_key
    attr_writer :base_url, :secret_key

    def initialize
      @base_url = nil
      @route_path = "/a"
      @secret_key = nil
      @dashboard_enabled = true
      @authenticate_dashboard = nil
      @after_click = nil
      @dedup_window = 5
    end

    # Base URL with Rails fallback
    def base_url
      @base_url || (defined?(Rails) && Rails.application.respond_to?(:routes) ? Rails.application.routes.default_url_options[:host] : nil)
    end

    # Secret key with Rails fallback
    def secret_key
      @secret_key || (defined?(Rails) && Rails.application ? Rails.application.secret_key_base&.first(32) : nil)
    end
  end
end
