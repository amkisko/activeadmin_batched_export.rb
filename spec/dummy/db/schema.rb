# frozen_string_literal: true

ActiveRecord::Schema.define(version: 20_260_904_153_000) do
  create_table :orders, force: :cascade do |t|
    t.string :email, null: false
    t.integer :priority
    t.timestamps
  end

  create_table :macro_probes, force: :cascade do |t|
    t.string :name, null: false
    t.timestamps
  end

  create_table :catalog_items, force: :cascade do |t|
    t.string :name, null: false
    t.timestamps
  end

  create_table :owned_notes, force: :cascade do |t|
    t.string :owner_key, null: false
    t.string :body, null: false
    t.timestamps
  end

  create_table :active_admin_batched_export_snapshot_rows, force: :cascade do |t|
    t.string :token, null: false
    t.string :resource_type, null: false
    t.bigint :record_id, null: false
    t.integer :position, null: false
    t.datetime :created_at, null: false
  end

  add_index :active_admin_batched_export_snapshot_rows, [:token, :position], unique: true,
    name: "index_export_snapshot_rows_on_token_and_position"
  add_index :active_admin_batched_export_snapshot_rows, :created_at,
    name: "index_export_snapshot_rows_on_created_at"
end
