# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "active_support"
require "active_support/testing/autorun"
require "active_support/cache"
require "active_support/key_generator"
require "action_view"
require "action_view/helpers"

# Mock Rails application for testing
class MockRoutes
  def default_url_options
    { host: "test.example.com", protocol: "https" }
  end
end

class MockApplication
  def key_generator
    @key_generator ||= ActiveSupport::KeyGenerator.new("test_secret_key_base")
  end

  def routes
    @routes ||= MockRoutes.new
  end
end

module Rails
  class << self
    def cache
      @cache ||= ActiveSupport::Cache::MemoryStore.new
    end

    def logger
      @logger ||= Logger.new($stdout, level: Logger::WARN)
    end

    def application
      @application ||= MockApplication.new
    end
  end
end

# Require gem components
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
