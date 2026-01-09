# frozen_string_literal: true

require "test_helper"

class ViewHelpersTest < Minitest::Test
  include AffiliateTracker::ViewHelpers
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::CaptureHelper

  attr_accessor :output_buffer

  def setup
    @output_buffer = ActionView::OutputBuffer.new
  end

  def test_affiliate_url_generates_tracking_url
    url = affiliate_url("https://shop.com")
    assert url.start_with?("https://test.example.com/a/")
    assert_match(/\?s=/, url)
  end

  def test_affiliate_url_with_metadata
    url = affiliate_url("https://shop.com", shop_id: 1, campaign: "test")

    # Decode and verify metadata is included
    payload = url.match(%r{/a/([^?]+)\?})[1]
    signature = url.match(/\?s=([a-f0-9]+)$/)[1]
    result = AffiliateTracker::UrlGenerator.decode(payload, signature)

    assert_equal 1, result[:metadata]["shop_id"]
    assert_equal "test", result[:metadata]["campaign"]
  end

  def test_affiliate_link_generates_anchor_tag
    html = affiliate_link("https://shop.com", "Visit Shop")
    assert_match(/<a /, html)
    assert_match(/Visit Shop/, html)
    assert_match(/href="https:\/\/test\.example\.com\/a\//, html)
  end

  def test_affiliate_link_includes_target_blank
    html = affiliate_link("https://shop.com", "Visit")
    assert_match(/target="_blank"/, html)
  end

  def test_affiliate_link_includes_noopener
    html = affiliate_link("https://shop.com", "Visit")
    assert_match(/rel="noopener"/, html)
  end

  def test_affiliate_link_with_metadata
    html = affiliate_link("https://shop.com", "Visit", shop_id: 42)

    # Extract URL from href
    href = html.match(/href="([^"]+)"/)[1]
    payload = href.match(%r{/a/([^?]+)\?})[1]
    signature = href.match(/\?s=([a-f0-9]+)$/)[1]
    result = AffiliateTracker::UrlGenerator.decode(payload, signature)

    assert_equal 42, result[:metadata]["shop_id"]
  end

  def test_affiliate_link_with_html_options
    html = affiliate_link("https://shop.com", "Visit", {}, { class: "btn btn-primary", id: "shop-link" })
    assert_match(/class="btn btn-primary"/, html)
    assert_match(/id="shop-link"/, html)
  end

  def test_affiliate_link_metadata_in_options_hash
    html = affiliate_link("https://shop.com", "Visit", shop_id: 1, class: "btn")

    # class should be in HTML, shop_id should be in tracking URL
    assert_match(/class="btn"/, html)

    href = html.match(/href="([^"]+)"/)[1]
    payload = href.match(%r{/a/([^?]+)\?})[1]
    signature = href.match(/\?s=([a-f0-9]+)$/)[1]
    result = AffiliateTracker::UrlGenerator.decode(payload, signature)

    assert_equal 1, result[:metadata]["shop_id"]
  end
end
