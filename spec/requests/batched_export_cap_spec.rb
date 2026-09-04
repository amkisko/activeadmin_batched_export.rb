# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Batched export row cap", type: :request do
  before do
    Order.delete_all
    Order.create!(email: "alpha@example.com")
    Order.create!(email: "beta@example.com")
    Order.create!(email: "gamma@example.com")
  end

  after do
    ActiveAdmin::BatchedExport.config.max_export_rows = nil
  end

  it "flags metadata when the collection is larger than the cap" do
    ActiveAdmin::BatchedExport.config.max_export_rows = 2

    get batched_export_admin_orders_path(
      format: :json,
      export_meta: "1",
      export_format: "csv"
    )

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body)
    expect(payload.fetch("over_max")).to be(true)
    expect(payload.fetch("max_export_rows")).to eq(2)
    expect(payload.fetch("total_count")).to eq(3)
  end

  it "refuses the first batch when the collection is larger than the cap" do
    ActiveAdmin::BatchedExport.config.max_export_rows = 2

    get batched_export_admin_orders_path(
      format: :csv,
      export_format: "csv"
    )

    expect(response).to have_http_status(:bad_request)
    expect(response.body).to include(I18n.t("active_admin.batched_export_page.over_max_rows"))
  end

  it "allows a collection equal to the cap" do
    ActiveAdmin::BatchedExport.config.max_export_rows = 3

    get batched_export_admin_orders_path(
      format: :csv,
      export_format: "csv"
    )

    expect(response).to have_http_status(:ok)
  end
end
