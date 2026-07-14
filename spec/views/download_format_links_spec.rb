# frozen_string_literal: true

require "rails_helper"

RSpec.describe "active_admin/shared/download_format_links", type: :view do
  let(:formats) { [:csv] }
  let(:query_parameters) { {"status" => "open"} }
  let(:request) { instance_double(ActionDispatch::Request, query_parameters: query_parameters) }

  before do
    view.lookup_context.prepend_view_paths([ActiveAdmin::BatchedExport::Engine.root.join("app/views").to_s])
    allow(view).to receive(:request).and_return(request)
    allow(view).to receive(:url_for) { |options| "URL:#{options.inspect}" }
  end

  it "links to batched export when export is enabled for the resource" do
    order_resource =
      ActiveAdmin.application.namespaces[:admin].resources.find do |resource|
        resource.resource_name.name == "Order"
      end

    allow(view).to receive(:active_admin_config).and_return(order_resource)

    render partial: "active_admin/shared/download_format_links", locals: {formats: formats}

    expect(rendered).to include("action: :batched_export")
  end

  it "links to standard format export when export is disabled for the resource" do
    catalog_item_resource =
      ActiveAdmin.application.namespaces[:admin].resources.find do |resource|
        resource.resource_name.name == "CatalogItem"
      end

    allow(view).to receive(:active_admin_config).and_return(catalog_item_resource)

    render partial: "active_admin/shared/download_format_links", locals: {formats: formats}

    expect(rendered).to include("format: :csv")
    expect(rendered).not_to include("action: :batched_export")
  end
end
