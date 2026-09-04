# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Batched export NULL sort keys", type: :request do
  def csv_ids(body)
    lines = body.lines.map { |line| line.strip.delete_prefix("\uFEFF") }.reject(&:empty?)
    lines = lines.drop(1) if lines.first&.start_with?("Id,")
    lines.map { |line| Integer(line.split(",", 2).first) }
  end

  def follow(previous)
    params = {
      format: :csv,
      export_format: "csv",
      order: "priority_asc",
      export_cursor: previous.headers.fetch("X-Batched-Export-Next")
    }
    token = previous.headers["X-Batched-Export-Snapshot"]
    params[:export_snapshot] = token if token.present?
    get batched_export_admin_orders_path(params)
    export_batch_response
  end

  it "places NULL sort keys last and returns each row once" do
    Order.delete_all
    low = Order.create!(email: "low@example.com", priority: 1)
    first_null = Order.create!(email: "null-a@example.com", priority: nil)
    high = Order.create!(email: "high@example.com", priority: 2)
    second_null = Order.create!(email: "null-b@example.com", priority: nil)

    get batched_export_admin_orders_path(
      format: :csv,
      export_format: "csv",
      order: "priority_asc"
    )
    first = export_batch_response
    second = follow(first)
    ids = csv_ids(first.body) + csv_ids(second.body)

    expect(ids).to eq([low.id, high.id, first_null.id, second_null.id])
  end
end
