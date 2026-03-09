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

    # Default metadata proc - called when generating URLs
    # Example: -> { { user_id: Current.user&.id } }
    attr_accessor :default_metadata

    # Fallback URL when signature is missing or invalid.
    # Can be a String (static URL) or a Proc that receives the decoded payload Hash.
    # The payload is decoded WITHOUT signature verification, so treat it as untrusted.
    # Default: "/" (homepage)
    #
    # Examples:
    #   config.fallback_url = "/oops"
    #   config.fallback_url = ->(payload) { payload&.dig("shop") ? "/#{payload["shop"]}" : "/" }
    attr_accessor :fallback_url

    def initialize
      @authenticate_dashboard = nil
      @after_click = nil
      @utm_source = 'affiliate'
      @utm_medium = 'referral'
      @ref_param = nil
      @default_metadata = nil
      @fallback_url = '/'
    end

    # Resolve fallback URL from config. Safely decodes payload (unverified) and
    # passes it to the proc. Returns "/" if anything goes wrong.
    def resolve_fallback_url(raw_payload)
      payload_data = decode_payload_unsafe(raw_payload)

      if @fallback_url.respond_to?(:call)
        result = @fallback_url.call(payload_data)
        result.presence || '/'
      else
        @fallback_url.to_s.presence || '/'
      end
    rescue StandardError
      '/'
    end

    def resolve_default_metadata
      return {} unless @default_metadata.respond_to?(:call)

      result = @default_metadata.call
      result.is_a?(Hash) ? result : {}
    rescue StandardError
      {}
    end

    def base_url
      # Try routes first, then ActionMailer::Base as fallback (Rails 8 way)
      options = Rails.application.routes.default_url_options.presence ||
                ActionMailer::Base.default_url_options.presence ||
                {}

      host = options[:host]
      unless host
        raise Error,
              "Set config.action_mailer.default_url_options = { host: 'example.com' } in config/environments/*.rb"
      end

      protocol = options[:protocol] || 'https'
      "#{protocol}://#{host}"
    end

    def secret_key
      Rails.application.key_generator.generate_key('affiliate_tracker', 32)
    end

    private

    # Decode Base64 payload without verifying signature.
    # Used only for building fallback URLs — treat result as untrusted.
    def decode_payload_unsafe(raw_payload)
      return nil if raw_payload.blank?

      JSON.parse(Base64.urlsafe_decode64(raw_payload))
    rescue StandardError
      nil
    end
  end
end
