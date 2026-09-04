# frozen_string_literal: true

require "spec_helper"
require "json"
require "base64"
require "activeadmin/batched_export/export_cursor"

RSpec.describe ActiveAdmin::BatchedExport::ExportCursor do
  it "round-trips field, direction, primary key, and sort value" do
    encoded = described_class.encode(
      field: "id",
      direction: "desc",
      primary_key: 12,
      sort_value: 12
    )

    payload = described_class.decode(encoded)
    expect(payload.field).to eq("id")
    expect(payload.direction).to eq("desc")
    expect(payload.primary_key).to eq(12)
    expect(payload.sort_value).to eq(12)
  end

  it "raises Invalid for garbage input" do
    expect { described_class.decode("%%%") }.to raise_error(described_class::Invalid)
  end

  it "round-trips a JSON null sort value and optional position" do
    encoded = described_class.encode(
      field: "priority",
      direction: "asc",
      primary_key: 9,
      sort_value: nil,
      position: 4
    )

    payload = described_class.decode(encoded)
    expect(payload.sort_value).to be_nil
    expect(payload.position).to eq(4)
  end

  it "raises Invalid when direction is not asc or desc" do
    tampered = Base64.urlsafe_encode64(
      JSON.generate({"f" => "id", "d" => "sideways", "k" => 1, "s" => 1}),
      padding: false
    )

    expect { described_class.decode(tampered) }.to raise_error(described_class::Invalid)
  end
end
