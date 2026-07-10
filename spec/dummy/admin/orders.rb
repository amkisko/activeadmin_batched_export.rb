# frozen_string_literal: true

ActiveAdmin.register Order do
  menu priority: 1

  actions :index

  index download_links: %i[csv json] do
    selectable_column
    id_column
    column :email
  end

  csv do
    column :id
    column :email
  end

  batched_export batch_size: 2, column_selection: true
end
