# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveAdmin::BatchedExport::Configuration do
  subject(:configuration) { described_class.new }

  it "defaults batch size to 1000" do
    expect(configuration.batch_size).to eq(1000)
  end

  it "defaults max batch size to 10000" do
    expect(configuration.max_batch_size).to eq(10_000)
  end

  it "defaults large export row threshold to 25000" do
    expect(configuration.large_export_row_threshold).to eq(25_000)
  end

  it "registers custom macros" do
    configuration.register_macro(:uppercase, ->(value, _record, _column) { value.to_s.upcase })
    expect(configuration.registered_macros[:uppercase].call("abc", nil, nil)).to eq("ABC")
  end
end
