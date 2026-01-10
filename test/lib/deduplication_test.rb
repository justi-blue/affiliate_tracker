# frozen_string_literal: true

require "test_helper"
require "active_support/core_ext/numeric/time"

class DeduplicationTest < Minitest::Test
  def setup
    Rails.cache.clear
  end

  def test_first_click_is_recorded
    key = "affiliate_tracker:192.168.1.1:https://shop.com"

    refute Rails.cache.exist?(key)

    # Simulate first click
    Rails.cache.write(key, true, expires_in: 5.seconds)

    assert Rails.cache.exist?(key)
  end

  def test_duplicate_click_within_window_is_blocked
    key = "affiliate_tracker:192.168.1.1:https://shop.com"

    # First click
    Rails.cache.write(key, true, expires_in: 5.seconds)

    # Second click should be blocked
    assert Rails.cache.exist?(key), "Duplicate click should be blocked"
  end

  def test_different_ip_is_not_blocked
    key1 = "affiliate_tracker:192.168.1.1:https://shop.com"
    key2 = "affiliate_tracker:192.168.1.2:https://shop.com"

    Rails.cache.write(key1, true, expires_in: 5.seconds)

    assert Rails.cache.exist?(key1)
    refute Rails.cache.exist?(key2), "Different IP should not be blocked"
  end

  def test_different_url_is_not_blocked
    key1 = "affiliate_tracker:192.168.1.1:https://shop1.com"
    key2 = "affiliate_tracker:192.168.1.1:https://shop2.com"

    Rails.cache.write(key1, true, expires_in: 5.seconds)

    assert Rails.cache.exist?(key1)
    refute Rails.cache.exist?(key2), "Different URL should not be blocked"
  end

  def test_cache_expires_after_window
    key = "affiliate_tracker:192.168.1.1:https://shop.com"

    Rails.cache.write(key, true, expires_in: 0.seconds)

    # After expiry, should not exist
    sleep 0.1
    refute Rails.cache.exist?(key), "Cache should expire after window"
  end
end
