# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Batched export freeze", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  def csv_ids(body)
    lines = body.lines.map { |line| line.strip.delete_prefix("\uFEFF") }.reject(&:empty?)
    lines = lines.drop(1) if lines.first&.start_with?("Id,")
    lines.map { |line| Integer(line.split(",", 2).first) }
  end

  def get_csv_batch(extra = {})
    get batched_export_admin_orders_path(
      {format: :csv, export_format: "csv"}.merge(extra)
    )
    export_batch_response
  end

  def follow_csv_batch(previous, extra = {})
    params = extra.merge(export_cursor: previous.headers.fetch("X-Batched-Export-Next"))
    token = previous.headers["X-Batched-Export-Snapshot"]
    params[:export_snapshot] = token if token.present?
    get_csv_batch(params)
  end

  it "omits a row inserted after freeze on an ascending walk" do
    Order.delete_all
    first_row = Order.create!(email: "one@example.com")
    second_row = Order.create!(email: "two@example.com")
    third_row = Order.create!(email: "three@example.com")

    first = get_csv_batch(order: "id_asc")
    expect(csv_ids(first.body)).to eq([first_row.id, second_row.id])
    expect(first.headers["X-Batched-Export-Snapshot"]).to be_present

    Order.create!(email: "four@example.com")
    second = follow_csv_batch(first, order: "id_asc")

    expect(csv_ids(second.body)).to eq([third_row.id])
  end

  it "refuses a later batch when the freeze session is gone" do
    Order.delete_all
    Order.create!(email: "one@example.com")
    Order.create!(email: "two@example.com")
    Order.create!(email: "three@example.com")

    first = get_csv_batch
    travel_to(2.days.from_now) do
      get batched_export_admin_orders_path(
        format: :csv,
        export_format: "csv",
        export_cursor: first.headers.fetch("X-Batched-Export-Next"),
        export_snapshot: first.headers.fetch("X-Batched-Export-Snapshot")
      )
    end

    expect(response).to have_http_status(:bad_request)
    expect(response.body).to include(I18n.t("active_admin.batched_export_page.unavailable_session"))
  end

  it "does not freeze ids when loading metadata" do
    Order.delete_all
    Order.create!(email: "one@example.com")

    expect {
      get batched_export_admin_orders_path(
        format: :json,
        export_meta: "1",
        export_format: "csv"
      )
    }.not_to change(ActiveAdmin::BatchedExport::SnapshotRow, :count)
  end
end
