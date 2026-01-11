# frozen_string_literal: true

module AffiliateTracker
  class Engine < ::Rails::Engine
    isolate_namespace AffiliateTracker

    initializer "affiliate_tracker.helpers" do
      ActiveSupport.on_load(:action_view) do
        include AffiliateTracker::ViewHelpers
      end

      ActiveSupport.on_load(:action_mailer) do
        include AffiliateTracker::ViewHelpers
      end
    end
  end
end

require_relative "view_helpers"
