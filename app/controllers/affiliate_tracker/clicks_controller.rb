# frozen_string_literal: true

module AffiliateTracker
  class ClicksController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:redirect]

    def redirect
      payload = params[:payload]
      signature = params[:s]

      begin
        data = UrlGenerator.decode(payload, signature)
        destination_url = data[:destination_url]
        metadata = data[:metadata]

        # Record the click (async-safe)
        record_click(destination_url, metadata)

        # Redirect to destination
        redirect_to destination_url, allow_other_host: true, status: :moved_permanently
      rescue AffiliateTracker::Error => e
        Rails.logger.warn "[AffiliateTracker] Invalid tracking URL: #{e.message}"
        render plain: "Invalid link", status: :bad_request
      end
    end

    private

    def record_click(destination_url, metadata)
      dedup_key = "#{request.remote_ip}:#{destination_url}"
      dedup_window = AffiliateTracker.configuration.dedup_window

      # Simple deduplication using Rails cache
      return if Rails.cache.exist?("affiliate_tracker:#{dedup_key}")
      Rails.cache.write("affiliate_tracker:#{dedup_key}", true, expires_in: dedup_window.seconds)

      click = Click.create!(
        destination_url: destination_url,
        ip_address: anonymize_ip(request.remote_ip),
        user_agent: request.user_agent&.truncate(500),
        referer: request.referer&.truncate(500),
        metadata: metadata,
        clicked_at: Time.current
      )

      # Call custom handler if configured
      if (handler = AffiliateTracker.configuration.after_click)
        handler.call(click)
      end
    rescue StandardError => e
      Rails.logger.error "[AffiliateTracker] Failed to record click: #{e.message}"
    end

    def anonymize_ip(ip)
      return nil if ip.blank?
      # Anonymize last octet for privacy
      parts = ip.split(".")
      return ip unless parts.size == 4
      parts[3] = "0"
      parts.join(".")
    end
  end
end
