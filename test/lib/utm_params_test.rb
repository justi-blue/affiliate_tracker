# frozen_string_literal: true

require "test_helper"
require "uri"

class UtmParamsTest < Minitest::Test
  def test_append_utm_to_simple_url
    url = "https://shop.com/product"
    metadata = { "campaign" => "summer", "shop" => "modago" }

    result = append_utm_params(url, metadata)
    uri = URI.parse(result)
    params = URI.decode_www_form(uri.query)

    assert_equal "affiliate", params.assoc("utm_source")&.last
    assert_equal "referral", params.assoc("utm_medium")&.last
    assert_equal "summer", params.assoc("utm_campaign")&.last
    assert_equal "modago", params.assoc("utm_content")&.last
  end

  def test_append_utm_to_url_with_existing_params
    url = "https://shop.com/product?color=red"
    metadata = { "campaign" => "winter" }

    result = append_utm_params(url, metadata)
    uri = URI.parse(result)
    params = URI.decode_www_form(uri.query)

    assert_equal "red", params.assoc("color")&.last
    assert_equal "winter", params.assoc("utm_campaign")&.last
  end

  def test_does_not_overwrite_existing_utm
    url = "https://shop.com/product?utm_source=google"
    metadata = { "campaign" => "test" }

    result = append_utm_params(url, metadata)
    uri = URI.parse(result)
    params = URI.decode_www_form(uri.query)

    # Should keep original utm_source
    assert_equal "google", params.assoc("utm_source")&.last
    # Should add utm_campaign
    assert_equal "test", params.assoc("utm_campaign")&.last
  end

  def test_metadata_overrides_defaults
    url = "https://shop.com/product"
    metadata = { "utm_source" => "newsletter", "utm_medium" => "email" }

    result = append_utm_params(url, metadata)
    uri = URI.parse(result)
    params = URI.decode_www_form(uri.query)

    assert_equal "newsletter", params.assoc("utm_source")&.last
    assert_equal "email", params.assoc("utm_medium")&.last
  end

  def test_handles_nil_campaign
    url = "https://shop.com/product"
    metadata = {}

    result = append_utm_params(url, metadata)
    uri = URI.parse(result)
    params = URI.decode_www_form(uri.query)

    assert_equal "affiliate", params.assoc("utm_source")&.last
    assert_nil params.assoc("utm_campaign")
  end

  def test_adds_ref_param_from_config
    url = "https://shop.com/product"
    metadata = { "campaign" => "summer" }

    AffiliateTracker.configuration.ref_param = "partnerJan"

    result = append_utm_params(url, metadata)
    uri = URI.parse(result)
    params = URI.decode_www_form(uri.query)

    assert_equal "partnerJan", params.assoc("ref")&.last
    assert_equal "summer", params.assoc("utm_campaign")&.last
  ensure
    AffiliateTracker.configuration.ref_param = nil
  end

  def test_does_not_add_ref_when_nil
    url = "https://shop.com/product"
    metadata = {}

    AffiliateTracker.configuration.ref_param = nil

    result = append_utm_params(url, metadata)
    uri = URI.parse(result)
    params = URI.decode_www_form(uri.query)

    assert_nil params.assoc("ref")
  end

  def test_does_not_overwrite_existing_ref
    url = "https://shop.com/product?ref=existing"
    metadata = {}

    AffiliateTracker.configuration.ref_param = "partnerJan"

    result = append_utm_params(url, metadata)
    uri = URI.parse(result)
    params = URI.decode_www_form(uri.query)

    assert_equal "existing", params.assoc("ref")&.last
  ensure
    AffiliateTracker.configuration.ref_param = nil
  end

  private

  def append_utm_params(url, metadata)
    uri = URI.parse(url)
    params = URI.decode_www_form(uri.query || "")

    config = AffiliateTracker.configuration
    tracking_params = {
      "ref" => config.ref_param,
      "utm_source" => metadata["utm_source"] || config.utm_source,
      "utm_medium" => metadata["utm_medium"] || config.utm_medium,
      "utm_campaign" => metadata["campaign"],
      "utm_content" => metadata["shop"]
    }.compact

    existing_keys = params.map(&:first)
    tracking_params.each do |key, value|
      params << [key, value] unless existing_keys.include?(key)
    end

    uri.query = URI.encode_www_form(params) if params.any?
    uri.to_s
  end
end
