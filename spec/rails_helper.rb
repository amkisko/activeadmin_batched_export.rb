# frozen_string_literal: true

require_relative "spec_helper"

ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"

DUMMY_ROOT = Rails.root unless defined?(DUMMY_ROOT)

ActiveRecord::Base.connection_pool.with_connection do |connection|
  unless connection.table_exists?(:orders)
    ActiveRecord::Schema.verbose = false
    load DUMMY_ROOT.join("db", "schema.rb").to_s
  end

  next if connection.table_exists?(:macro_probes)

  ActiveRecord::Schema.verbose = false
  connection.create_table :macro_probes, force: :cascade do |table|
    table.string :name, null: false
    table.timestamps
  end

  next if connection.table_exists?(:catalog_items)

  ActiveRecord::Schema.verbose = false
  connection.create_table :catalog_items, force: :cascade do |table|
    table.string :name, null: false
    table.timestamps
  end
end

require "rspec/rails"
require "activeadmin"
require "activeadmin_batched_export"

ActiveAdmin.application.load!
Rails.application.reload_routes!

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end
