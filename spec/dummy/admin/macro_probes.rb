# frozen_string_literal: true

ActiveAdmin.register MacroProbe do
  actions :index

  index download_links: [:csv] do
    column :name
  end

  csv do
    column :name, macro: :missing_macro
  end
end
