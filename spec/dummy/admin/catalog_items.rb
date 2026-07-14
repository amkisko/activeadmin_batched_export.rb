# frozen_string_literal: true

ActiveAdmin.register CatalogItem do
  actions :index

  index download_links: [:csv] do
    column :name
  end

  csv do
    column :name
  end
end
