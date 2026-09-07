# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Batched export", type: :request do
  def concat_json_array_chunks(texts)
    inners = texts.filter_map do |text|
      trimmed = text.strip
      next if trimmed.empty? || trimmed == "[]"

      trimmed[1..-2]
    end
    return "[]" if inners.empty?

    "[#{inners.join(",")}]"
  end

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

    it "rejects a data format that does not match export_format" do
      get batched_export_admin_orders_path(
        format: :json,
        export_format: "csv"
      )

      expect(response).to have_http_status(:not_acceptable)
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
        export_format: "csv"
      )

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/csv")
      expect(response.body).to include("Id")
      expect(response.body).to include("Email")
      expect(response.body).to include("@example.com")
      expect(response.headers["X-Batched-Export-Next"]).to be_present
    end

    it "rejects formats that are not enabled on the index" do
      get batched_export_admin_orders_path(
        format: :xml,
        export_format: "xml"
      )

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns a JSON array chunk for enabled JSON exports" do
      get batched_export_admin_orders_path(
        format: :json,
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

    it "omits CSV headers on later cursor pages" do
      first = get_csv_batch
      second = follow_csv_batch(first)

      expect(response).to have_http_status(:ok)
      lines = response.body.lines.map(&:strip).reject(&:empty?)
      expect(lines).not_to include("Id,Email")
      expect(lines.length).to eq(1)
      expect(lines.first).to include("@example.com")
      expect(response.headers["X-Batched-Export-Next"]).to be_blank
    end

    it "ends the walk on a short last page without a next cursor" do
      first = get_csv_batch
      second = follow_csv_batch(first)

      expect(second.body).to include("@example.com")
      expect(second.headers["X-Batched-Export-Next"]).to be_blank
    end

    it "returns the first page again when no cursor is given on an extra request" do
      first = get_csv_batch
      second = get_csv_batch

      expect(second.body).to eq(first.body)
      expect(second.headers["X-Batched-Export-Next"]).to eq(first.headers["X-Batched-Export-Next"])
    end

    it "rejects an invalid export cursor" do
      get batched_export_admin_orders_path(
        format: :csv,
        export_format: "csv",
        export_cursor: "%%%"
      )

      expect(response).to have_http_status(:bad_request)
    end

    it "exports only selected columns when export_columns is present" do
      get batched_export_admin_orders_path(
        format: :csv,
        export_format: "csv",
        export_columns: ["1"]
      )

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Email")
      expect(response.body).not_to include("Id")
      expect(response.body.scan(/@example\.com/).length).to eq(2)
    end

    it "returns bad request when export_columns resolve no columns" do
      get batched_export_admin_orders_path(
        format: :csv,
        export_format: "csv",
        export_columns: ["99"]
      )

      expect(response).to have_http_status(:bad_request)
      expect(response.body).to include(I18n.t("active_admin.batched_export_page.select_at_least_one_column"))
    end
  end

  describe "keyset walk" do
    it "does not duplicate a row when a higher id is inserted after the first page" do
      first = get_csv_batch
      first_ids = csv_ids(first.body)
      expect(first_ids.length).to eq(2)

      Order.create!(email: "delta@example.com")
      second = follow_csv_batch(first)
      second_ids = csv_ids(second.body)

      expect(second_ids & first_ids).to eq([])
      expect(second_ids.length).to eq(1)
      expect(Order.order(id: :desc).limit(1).pick(:id)).not_to eq(second_ids.first)
    end

    it "does not skip a later row when an already-exported row is deleted" do
      Order.delete_all
      first_row = Order.create!(email: "one@example.com")
      second_row = Order.create!(email: "two@example.com")
      third_row = Order.create!(email: "three@example.com")
      fourth_row = Order.create!(email: "four@example.com")

      first = get_csv_batch(order: "id_asc")
      expect(csv_ids(first.body)).to eq([first_row.id, second_row.id])

      first_row.destroy!
      second = follow_csv_batch(first, order: "id_asc")

      expect(csv_ids(second.body)).to eq([third_row.id, fourth_row.id])
    end

    it "concatenates JSON array chunks as text into one array of all rows" do
      first = get_json_batch
      second = follow_json_batch(first)

      combined = JSON.parse(concat_json_array_chunks([first.body, second.body]))
      expect(combined.length).to eq(3)
      expect(combined.map { |row| row.fetch("Id") }.uniq.length).to eq(3)
    end
  end

  def get_csv_batch(extra = {})
    get batched_export_admin_orders_path(
      {format: :csv, export_format: "csv"}.merge(extra)
    )
    export_batch_response
  end

  def get_json_batch(extra = {})
    get batched_export_admin_orders_path(
      {format: :json, export_format: "json"}.merge(extra)
    )
    export_batch_response
  end

  def follow_csv_batch(previous, extra = {})
    get_csv_batch(follow_params(previous, extra))
  end

  def follow_json_batch(previous, extra = {})
    get_json_batch(follow_params(previous, extra))
  end

  def follow_params(previous, extra)
    params = extra.merge(export_cursor: previous.headers.fetch("X-Batched-Export-Next"))
    token = previous.headers["X-Batched-Export-Snapshot"]
    params[:export_snapshot] = token if token.present?
    params
  end

  def csv_ids(body)
    lines = body.lines.map { |line| line.strip.delete_prefix("\uFEFF") }.reject(&:empty?)
    lines = lines.drop(1) if lines.first&.start_with?("Id,")
    lines.map { |line| Integer(line.split(",", 2).first) }
  end
end
