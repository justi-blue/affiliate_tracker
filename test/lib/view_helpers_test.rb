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

  # === Edge Cases for HTML Attributes ===

  def test_affiliate_link_with_inline_style
    html = affiliate_link("https://shop.com", "Buy Now",
      style: "background-color: #0f172a; color: #fff;")

    assert_match(/style="background-color: #0f172a; color: #fff;"/, html)
  end

  def test_affiliate_link_style_not_in_payload
    html = affiliate_link("https://shop.com", "Buy",
      shop: "test", style: "color: red;")

    href = html.match(/href="([^"]+)"/)[1]
    payload = href.match(%r{/a/([^?]+)\?})[1]
    signature = href.match(/\?s=([a-f0-9]+)$/)[1]
    result = AffiliateTracker::UrlGenerator.decode(payload, signature)

    # style should NOT be in metadata
    assert_nil result[:metadata]["style"]
    # shop SHOULD be in metadata
    assert_equal "test", result[:metadata]["shop"]
  end

  def test_affiliate_link_with_all_html_attributes
    html = affiliate_link("https://shop.com", "Click",
      class: "btn btn-primary",
      id: "main-cta",
      style: "padding: 10px;",
      campaign: "summer")

    assert_match(/class="btn btn-primary"/, html)
    assert_match(/id="main-cta"/, html)
    assert_match(/style="padding: 10px;"/, html)

    # campaign should be in payload, not HTML
    refute_match(/campaign/, html.gsub(/href="[^"]+"/, ""))
  end

  def test_affiliate_link_override_target
    html = affiliate_link("https://shop.com", "Visit",
      target: "_self")

    assert_match(/target="_self"/, html)
    refute_match(/target="_blank"/, html)
  end

  def test_affiliate_link_override_rel
    html = affiliate_link("https://shop.com", "Visit",
      rel: "nofollow noopener")

    assert_match(/rel="nofollow noopener"/, html)
  end

  # === Edge Cases for URLs ===

  def test_affiliate_link_with_url_having_query_params
    html = affiliate_link("https://shop.com/product?color=red&size=xl", "Buy")

    href = html.match(/href="([^"]+)"/)[1]
    payload = href.match(%r{/a/([^?]+)\?})[1]
    signature = href.match(/\?s=([a-f0-9]+)$/)[1]
    result = AffiliateTracker::UrlGenerator.decode(payload, signature)

    assert_equal "https://shop.com/product?color=red&size=xl", result[:destination_url]
  end

  def test_affiliate_link_with_url_having_fragment
    html = affiliate_link("https://shop.com/page#section", "Go")

    href = html.match(/href="([^"]+)"/)[1]
    payload = href.match(%r{/a/([^?]+)\?})[1]
    signature = href.match(/\?s=([a-f0-9]+)$/)[1]
    result = AffiliateTracker::UrlGenerator.decode(payload, signature)

    assert_equal "https://shop.com/page#section", result[:destination_url]
  end

  def test_affiliate_link_with_unicode_in_url
    html = affiliate_link("https://shop.pl/sukienka-żółta", "Zobacz")

    href = html.match(/href="([^"]+)"/)[1]
    assert href.start_with?("https://test.example.com/a/")
  end

  # === Edge Cases for Text Content ===

  def test_affiliate_link_with_unicode_text
    html = affiliate_link("https://shop.com", "Zobacz promocję 🎉")

    assert_match(/Zobacz promocję 🎉/, html)
  end

  def test_affiliate_link_with_html_entities_in_text
    html = affiliate_link("https://shop.com", "Price < $100 & free shipping")

    # Should be escaped
    assert_match(/Price &lt; \$100 &amp; free shipping/, html)
  end

  def test_affiliate_link_with_block_syntax
    html = affiliate_link("https://shop.com", shop: "test") do
      "Block Content"
    end

    assert_match(/Block Content/, html)
    assert_match(/href="https:\/\/test\.example\.com\/a\//, html)
  end

  def test_affiliate_link_block_with_html_content
    html = affiliate_link("https://shop.com", shop: "test") do
      "<strong>Bold</strong> text".html_safe
    end

    assert_match(/<strong>Bold<\/strong> text/, html)
  end

  # === Edge Cases for Metadata ===

  def test_affiliate_link_with_numeric_metadata
    html = affiliate_link("https://shop.com", "Buy",
      promotion_id: 123, price: 99.99)

    href = html.match(/href="([^"]+)"/)[1]
    payload = href.match(%r{/a/([^?]+)\?})[1]
    signature = href.match(/\?s=([a-f0-9]+)$/)[1]
    result = AffiliateTracker::UrlGenerator.decode(payload, signature)

    assert_equal 123, result[:metadata]["promotion_id"]
    assert_equal 99.99, result[:metadata]["price"]
  end

  def test_affiliate_link_with_nil_metadata_values
    html = affiliate_link("https://shop.com", "Buy",
      shop: "test", campaign: nil)

    href = html.match(/href="([^"]+)"/)[1]
    payload = href.match(%r{/a/([^?]+)\?})[1]
    signature = href.match(/\?s=([a-f0-9]+)$/)[1]
    result = AffiliateTracker::UrlGenerator.decode(payload, signature)

    assert_equal "test", result[:metadata]["shop"]
    # nil values should not be present or should be nil
    assert_nil result[:metadata]["campaign"]
  end

  def test_affiliate_link_preserves_metadata_with_special_chars
    html = affiliate_link("https://shop.com", "Buy",
      shop: "Shop & Store", campaign: "50% off!")

    href = html.match(/href="([^"]+)"/)[1]
    payload = href.match(%r{/a/([^?]+)\?})[1]
    signature = href.match(/\?s=([a-f0-9]+)$/)[1]
    result = AffiliateTracker::UrlGenerator.decode(payload, signature)

    assert_equal "Shop & Store", result[:metadata]["shop"]
    assert_equal "50% off!", result[:metadata]["campaign"]
  end

  # === affiliate_url edge cases ===

  def test_affiliate_url_with_empty_metadata
    url = affiliate_url("https://shop.com")

    payload = url.match(%r{/a/([^?]+)\?})[1]
    signature = url.match(/\?s=([a-f0-9]+)$/)[1]
    result = AffiliateTracker::UrlGenerator.decode(payload, signature)

    assert_equal "https://shop.com", result[:destination_url]
    assert_empty result[:metadata]
  end

  def test_affiliate_url_signature_is_valid
    url = affiliate_url("https://shop.com", test: "value")

    payload = url.match(%r{/a/([^?]+)\?})[1]
    signature = url.match(/\?s=([a-f0-9]+)$/)[1]

    # Should not raise
    result = AffiliateTracker::UrlGenerator.decode(payload, signature)
    assert_equal "https://shop.com", result[:destination_url]
  end

  def test_affiliate_url_different_urls_have_different_signatures
    url1 = affiliate_url("https://shop1.com")
    url2 = affiliate_url("https://shop2.com")

    sig1 = url1.match(/\?s=([a-f0-9]+)$/)[1]
    sig2 = url2.match(/\?s=([a-f0-9]+)$/)[1]

    refute_equal sig1, sig2
  end

  # === User Tracking Tests ===

  def test_affiliate_link_with_user_id
    html = affiliate_link("https://shop.com", "Buy", user_id: 123)

    href = html.match(/href="([^"]+)"/)[1]
    payload = href.match(%r{/a/([^?]+)\?})[1]
    signature = href.match(/\?s=([a-f0-9]+)$/)[1]
    result = AffiliateTracker::UrlGenerator.decode(payload, signature)

    assert_equal 123, result[:metadata]["user_id"]
  end

  def test_affiliate_link_with_full_tracking
    html = affiliate_link("https://shop.com", "View Deal",
      user_id: 42,
      shop_id: 10,
      promotion_id: 99,
      campaign: "daily_digest")

    href = html.match(/href="([^"]+)"/)[1]
    payload = href.match(%r{/a/([^?]+)\?})[1]
    signature = href.match(/\?s=([a-f0-9]+)$/)[1]
    result = AffiliateTracker::UrlGenerator.decode(payload, signature)

    assert_equal 42, result[:metadata]["user_id"]
    assert_equal 10, result[:metadata]["shop_id"]
    assert_equal 99, result[:metadata]["promotion_id"]
    assert_equal "daily_digest", result[:metadata]["campaign"]
  end

  def test_affiliate_link_without_user_id
    html = affiliate_link("https://shop.com", "Buy", campaign: "test")

    href = html.match(/href="([^"]+)"/)[1]
    payload = href.match(%r{/a/([^?]+)\?})[1]
    signature = href.match(/\?s=([a-f0-9]+)$/)[1]
    result = AffiliateTracker::UrlGenerator.decode(payload, signature)

    assert_nil result[:metadata]["user_id"]
    assert_equal "test", result[:metadata]["campaign"]
  end

  def test_affiliate_url_with_user_id
    url = affiliate_url("https://shop.com", user_id: 456, campaign: "homepage")

    payload = url.match(%r{/a/([^?]+)\?})[1]
    signature = url.match(/\?s=([a-f0-9]+)$/)[1]
    result = AffiliateTracker::UrlGenerator.decode(payload, signature)

    assert_equal 456, result[:metadata]["user_id"]
    assert_equal "homepage", result[:metadata]["campaign"]
  end
end
