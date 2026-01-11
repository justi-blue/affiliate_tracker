# frozen_string_literal: true

require_relative "affiliate_tracker/version"
require_relative "affiliate_tracker/configuration"

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

    # Generate a trackable affiliate URL
    def track_url(destination_url, metadata = {})
      merged_metadata = configuration.resolve_default_metadata.merge(metadata)
      UrlGenerator.new(destination_url, merged_metadata).generate
    end

    # Shorthand for track_url
    def url(destination_url, **metadata)
      track_url(destination_url, metadata)
    end
  end
end

require_relative "affiliate_tracker/engine" if defined?(Rails)
require_relative "affiliate_tracker/url_generator"
