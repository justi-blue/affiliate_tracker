# frozen_string_literal: true

require "base64"
require "openssl"
require "json"

module AffiliateTracker
  class UrlGenerator
    attr_reader :destination_url, :metadata

    def initialize(destination_url, metadata = {})
      @destination_url = destination_url
      @metadata = metadata.transform_keys(&:to_s)
    end

    def generate
      payload = encode_payload
      signature = sign(payload)
      "#{base_url}#{route_path}/#{payload}?s=#{signature}"
    end

    private

    def encode_payload
      data = { u: destination_url }.merge(metadata)
      Base64.urlsafe_encode64(data.to_json, padding: false)
    end

    def sign(payload)
      OpenSSL::HMAC.hexdigest("SHA256", secret_key, payload).first(16)
    end

    def base_url
      AffiliateTracker.configuration.base_url or raise Error, "base_url not configured"
    end

    def route_path
      AffiliateTracker.configuration.route_path
    end

    def secret_key
      AffiliateTracker.configuration.secret_key or raise Error, "secret_key not configured"
    end

    class << self
      def decode(payload, signature)
        expected_sig = OpenSSL::HMAC.hexdigest(
          "SHA256",
          AffiliateTracker.configuration.secret_key,
          payload
        ).first(16)

        raise Error, "Invalid signature" unless secure_compare(expected_sig, signature)

        data = JSON.parse(Base64.urlsafe_decode64(payload))
        {
          destination_url: data.delete("u"),
          metadata: data
        }
      end

      private

      def secure_compare(a, b)
        return false unless a.bytesize == b.bytesize
        a.bytes.zip(b.bytes).reduce(0) { |sum, (x, y)| sum | (x ^ y) }.zero?
      end
    end
  end
end
