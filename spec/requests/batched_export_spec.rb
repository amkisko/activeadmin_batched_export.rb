# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Batched export", type: :request do
  before do
    Order.delete_all
    Order.create!(email: "alpha@example.com")
    Order.create!(email: "beta@example.com")
    Order.create!(email: "gamma@example.com")
  end

  describe "GET /admin/orders/batched_export" do
    it "rejects unknown export formats" do
      get batched_export_admin_orders_path(export_format: "pdf")

      expect(response).to have_http_status(:bad_request)
      expect(response.body).to include("Invalid export format")
    end

    it "rejects formats that are not enabled on the index workspace page" do
      get batched_export_admin_orders_path(export_format: "xml")

      expect(response).not_to have_http_status(:ok)
      expect(response.body).not_to include(I18n.t("active_admin.batched_export_page.summary_title"))
    end

    it "flags large exports in metadata when the row threshold is exceeded" do
      previous_threshold = ActiveAdmin::BatchedExport.config.large_export_row_threshold
      ActiveAdmin::BatchedExport.config.large_export_row_threshold = 2

      get batched_export_admin_orders_path(
        format: :json,
        export_meta: "1",
        export_format: "csv"
      )

      expect(response).to have_http_status(:ok)
      payload = JSON.parse(response.body)
      expect(payload.fetch("large_export")).to be(true)
    ensure
      ActiveAdmin::BatchedExport.config.large_export_row_threshold = previous_threshold
    end
  end

  describe "export metadata" do
    it "returns batch counts for the filtered collection" do
      get batched_export_admin_orders_path(
        format: :json,
        export_meta: "1",
        export_format: "csv"
      )

      expect(response).to have_http_status(:ok)
      payload = JSON.parse(response.body)
      expect(payload.fetch("total_count")).to eq(3)
      expect(payload.fetch("total_batches")).to eq(2)
      expect(payload.fetch("batch_size")).to eq(2)
      expect(payload.fetch("export_format")).to eq("csv")
    end

    it "clamps batch size to the configured maximum" do
      previous_maximum = ActiveAdmin::BatchedExport.config.max_batch_size
      ActiveAdmin::BatchedExport.config.max_batch_size = 1

      get batched_export_admin_orders_path(
        format: :json,
        export_meta: "1",
        export_format: "csv"
      )

      expect(response).to have_http_status(:ok)
      payload = JSON.parse(response.body)
      expect(payload.fetch("batch_size")).to eq(1)
      expect(payload.fetch("total_batches")).to eq(3)
    ensure
      ActiveAdmin::BatchedExport.config.max_batch_size = previous_maximum
    end
  end

  describe "batch pages" do
    it "returns a CSV chunk with headers on the first page" do
      get batched_export_admin_orders_path(
        format: :csv,
        batch_page: 1,
        export_format: "csv"
      )

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/csv")
      expect(response.body).to include("Id")
      expect(response.body).to include("Email")
      expect(response.body).to include("@example.com")
    end

    it "rejects formats that are not enabled on the index" do
      get batched_export_admin_orders_path(
        format: :xml,
        batch_page: 1,
        export_format: "xml"
      )

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns a JSON array chunk for enabled JSON exports" do
      get batched_export_admin_orders_path(
        format: :json,
        batch_page: 1,
        export_format: "json"
      )

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/json")
      payload = JSON.parse(response.body)
      expect(payload).to be_an(Array)
      expect(payload.length).to eq(2)
      expect(payload).to all(include("Id", "Email"))
      emails = payload.map { |row| row.fetch("Email") }
      expect(emails).to all(include("@example.com"))
    end

    it "omits CSV headers on later batch pages" do
      get batched_export_admin_orders_path(
        format: :csv,
        batch_page: 2,
        export_format: "csv"
      )

      expect(response).to have_http_status(:ok)
      lines = response.body.lines.map(&:strip).reject(&:empty?)
      expect(lines).not_to include("Id,Email")
      expect(lines.length).to eq(1)
      expect(lines.first).to include("@example.com")
    end

    it "returns not found for batch pages beyond the collection" do
      get batched_export_admin_orders_path(
        format: :csv,
        batch_page: 99,
        export_format: "csv"
      )

      expect(response).to have_http_status(:not_found)
    end

    it "exports only selected columns when export_columns is present" do
      get batched_export_admin_orders_path(
        format: :csv,
        batch_page: 1,
        export_format: "csv",
        export_columns: ["1"]
      )

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Email")
      expect(response.body).not_to include("Id")
      expect(response.body.scan(/@example\.com/).length).to eq(2)
    end
  end
end
