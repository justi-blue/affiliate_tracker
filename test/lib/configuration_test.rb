# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @config = AffiliateTracker::Configuration.new
  end

  def test_base_url_from_rails_routes
    assert_equal "https://test.example.com", @config.base_url
  end

  def test_secret_key_from_rails_key_generator
    key = @config.secret_key
    assert_equal 32, key.bytesize
  end

  def test_can_set_authenticate_dashboard
    auth_proc = -> { redirect_to login_path }
    @config.authenticate_dashboard = auth_proc
    assert_equal auth_proc, @config.authenticate_dashboard
  end

  def test_can_set_after_click
    handler = ->(click) { puts click.id }
    @config.after_click = handler
    assert_equal handler, @config.after_click
  end

  def test_authenticate_dashboard_default_nil
    assert_nil @config.authenticate_dashboard
  end

  def test_after_click_default_nil
    assert_nil @config.after_click
  end
end

class AffiliateTrackerConfigureTest < Minitest::Test
  def test_configure_yields_configuration
    AffiliateTracker.configure do |config|
      assert_instance_of AffiliateTracker::Configuration, config
    end
  end

  def test_track_url_shorthand
    url = AffiliateTracker.url("https://shop.com", shop_id: 1)
    assert url.start_with?("https://test.example.com/a/")
    assert_match(/\?s=/, url)
  end

  def test_track_url_method
    url = AffiliateTracker.track_url("https://shop.com", { shop_id: 1 })
    assert url.start_with?("https://test.example.com/a/")
  end
end
