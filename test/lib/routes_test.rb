# frozen_string_literal: true

require "test_helper"

class RoutesTest < Minitest::Test
  def test_dashboard_route_is_defined_before_payload_catch_all
    routes_file = File.read(File.expand_path("../../config/routes.rb", __dir__))

    dashboard_position = routes_file.index('get "/dashboard"')
    payload_position = routes_file.index('get "/:payload"')

    assert dashboard_position, "Dashboard route should be defined"
    assert payload_position, "Payload route should be defined"
    assert dashboard_position < payload_position,
      "Dashboard route must come before /:payload catch-all to avoid being matched as payload"
  end

  def test_dashboard_path_is_not_valid_base64_payload
    # "dashboard" decoded as base64 would fail, proving it's not a valid tracking payload
    # This ensures requests to /dashboard go to dashboard controller, not clicks controller
    require "base64"

    decoded = Base64.urlsafe_decode64("dashboard") rescue nil
    assert_nil decoded, "dashboard should not be a valid base64 payload"
  end
end
