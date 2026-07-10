# frozen_string_literal: true

ActiveRecord::Schema.define(version: 20_260_706_120_000) do
  create_table :orders, force: :cascade do |t|
    t.string :email, null: false
    t.timestamps
  end

  create_table :macro_probes, force: :cascade do |t|
    t.string :name, null: false
    t.timestamps
  end
end
