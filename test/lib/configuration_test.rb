# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @config = AffiliateTracker::Configuration.new
  end

  def test_default_route_path
    assert_equal "/a", @config.route_path
  end

  def test_default_dashboard_enabled
    assert @config.dashboard_enabled
  end

  def test_default_dedup_window
    assert_equal 5, @config.dedup_window
  end

  def test_can_set_base_url
    @config.base_url = "https://myapp.com"
    assert_equal "https://myapp.com", @config.base_url
  end

  def test_can_set_route_path
    @config.route_path = "/track"
    assert_equal "/track", @config.route_path
  end

  def test_can_set_secret_key
    @config.secret_key = "my_secret"
    assert_equal "my_secret", @config.secret_key
  end

  def test_can_disable_dashboard
    @config.dashboard_enabled = false
    refute @config.dashboard_enabled
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

  def test_can_set_dedup_window
    @config.dedup_window = 10
    assert_equal 10, @config.dedup_window
  end
end

class AffiliateTrackerConfigureTest < Minitest::Test
  def teardown
    # Reset configuration after each test
    AffiliateTracker.configure do |config|
      config.base_url = "https://test.example.com"
      config.secret_key = "test_secret_key_1234567890"
      config.route_path = "/a"
    end
  end

  def test_configure_yields_configuration
    AffiliateTracker.configure do |config|
      assert_instance_of AffiliateTracker::Configuration, config
    end
  end

  def test_configure_persists_settings
    AffiliateTracker.configure do |config|
      config.base_url = "https://configured.com"
    end

    assert_equal "https://configured.com", AffiliateTracker.configuration.base_url
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
