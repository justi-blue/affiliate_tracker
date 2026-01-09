# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "active_support"
require "active_support/testing/autorun"
require "active_support/cache"
require "action_view"
require "action_view/helpers"

# Mock Rails for testing (before requiring affiliate_tracker)
module Rails
  class << self
    def cache
      @cache ||= ActiveSupport::Cache::MemoryStore.new
    end

    def logger
      @logger ||= Logger.new($stdout, level: Logger::WARN)
    end

    def application
      @application ||= OpenStruct.new(
        secret_key_base: "test_secret_key_base_1234567890abcdef"
      )
    end
  end
end

# Require only the non-engine parts for testing
require "affiliate_tracker/version"
require "affiliate_tracker/configuration"
require "affiliate_tracker/url_generator"
require "affiliate_tracker/view_helpers"

# Set up main module
module AffiliateTracker
  class Error < StandardError; end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def track_url(destination_url, metadata = {})
      UrlGenerator.new(destination_url, metadata).generate
    end

    def url(destination_url, **metadata)
      track_url(destination_url, metadata)
    end
  end
end

# Configure for tests
AffiliateTracker.configure do |config|
  config.base_url = "https://test.example.com"
  config.secret_key = "test_secret_key_1234567890"
  config.route_path = "/a"
  config.dedup_window = 5
end
