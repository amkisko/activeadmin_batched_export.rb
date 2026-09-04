# frozen_string_literal: true

ActiveAdmin.register OwnedNote do
  actions :index

  index download_links: %i[csv json] do
    id_column
    column :owner_key
    column :body
  end

  csv do
    column :id
    column :owner_key
    column :body
  end

  controller do
    def scoped_collection
      owner_key = request.headers["X-Export-Owner"]
      return super.none if owner_key.blank?

      super.where(owner_key: owner_key)
    end
  end

  batched_export batch_size: 10
end
