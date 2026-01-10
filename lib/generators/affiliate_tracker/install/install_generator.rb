# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module AffiliateTracker
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def copy_migration
        migration_template "create_affiliate_tracker_clicks.rb.tt",
                           "db/migrate/create_affiliate_tracker_clicks.rb"
      end

      def create_initializer
        template "initializer.rb", "config/initializers/affiliate_tracker.rb"
      end

      def mount_engine
        route 'mount AffiliateTracker::Engine, at: "/a"'
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
