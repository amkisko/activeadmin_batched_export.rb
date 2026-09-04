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

  unless connection.column_exists?(:orders, :priority)
    connection.add_column :orders, :priority, :integer
  end

  unless connection.table_exists?(:macro_probes)
    ActiveRecord::Schema.verbose = false
    connection.create_table :macro_probes, force: :cascade do |table|
      table.string :name, null: false
      table.timestamps
    end
  end

  unless connection.table_exists?(:catalog_items)
    ActiveRecord::Schema.verbose = false
    connection.create_table :catalog_items, force: :cascade do |table|
      table.string :name, null: false
      table.timestamps
    end
  end

  unless connection.table_exists?(:owned_notes)
    ActiveRecord::Schema.verbose = false
    connection.create_table :owned_notes, force: :cascade do |table|
      table.string :owner_key, null: false
      table.string :body, null: false
      table.timestamps
    end
  end

  unless connection.table_exists?(:active_admin_batched_export_snapshot_rows)
    ActiveRecord::Schema.verbose = false
    connection.create_table :active_admin_batched_export_snapshot_rows, force: :cascade do |table|
      table.string :token, null: false
      table.string :resource_type, null: false
      table.bigint :record_id, null: false
      table.integer :position, null: false
      table.datetime :created_at, null: false
    end
    connection.add_index :active_admin_batched_export_snapshot_rows, [:token, :position], unique: true,
      name: "index_export_snapshot_rows_on_token_and_position"
    connection.add_index :active_admin_batched_export_snapshot_rows, :created_at,
      name: "index_export_snapshot_rows_on_created_at"
  end
end

require "rspec/rails"
require "activeadmin"
require "activeadmin_batched_export"
require_relative "support/export_batch_helpers"

ActiveAdmin.application.load!
Rails.application.reload_routes!

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.include ExportBatchHelpers, type: :request
end
