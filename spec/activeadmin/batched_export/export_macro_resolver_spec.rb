# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveAdmin::BatchedExport::ExportMacroResolver do
  Column = Struct.new(:name, :data, :options)

  it "applies column-level macro options" do
    columns = [Column.new(name: "Email", data: :email, options: {macro: :mask_email})]
    row = ["person@example.com"]

    result = described_class.apply(
      row: row,
      columns: columns,
      resource: nil,
      resource_settings: {},
      registry: {}
    )

    expect(result.first).to eq("pe***@example.com")
  end

  it "applies resource-level macro map by attribute" do
    columns = [Column.new(name: "Email", data: :email, options: {})]
    row = ["person@example.com"]

    result = described_class.apply(
      row: row,
      columns: columns,
      resource: nil,
      resource_settings: {macros: {email: :mask_email}},
      registry: {}
    )

    expect(result.first).to eq("pe***@example.com")
  end

  it "prefers column macro over resource map" do
    columns = [Column.new(name: "Email", data: :email, options: {macro: :redact})]
    row = ["person@example.com"]

    result = described_class.apply(
      row: row,
      columns: columns,
      resource: nil,
      resource_settings: {macros: {email: :mask_email}},
      registry: {}
    )

    expect(result.first).to eq("[redacted]")
  end
end
