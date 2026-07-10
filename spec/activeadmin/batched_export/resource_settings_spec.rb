# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::BatchedExport::ResourceSettings do
  let(:resource) do
    Class.new do
      include ActiveAdmin::BatchedExport::ResourceSettings
    end.new
  end

  around do |example|
    original_enabled = ActiveAdmin::BatchedExport.config.default_enabled
    original_column_selection = ActiveAdmin::BatchedExport.config.default_column_selection
    original_batch_size = ActiveAdmin::BatchedExport.config.batch_size
    original_max_batch_size = ActiveAdmin::BatchedExport.config.max_batch_size
    example.run
  ensure
    ActiveAdmin::BatchedExport.configure do |configuration|
      configuration.default_enabled = original_enabled
      configuration.default_column_selection = original_column_selection
      configuration.batch_size = original_batch_size
      configuration.max_batch_size = original_max_batch_size
    end
  end

  describe "#batched_export_enabled?" do
    it "defaults to the global configuration" do
      ActiveAdmin::BatchedExport.configure { |config| config.default_enabled = true }
      expect(resource.batched_export_enabled?).to be(true)

      ActiveAdmin::BatchedExport.configure { |config| config.default_enabled = false }
      expect(resource.batched_export_enabled?).to be(false)
    end

    it "honors per-resource enabled: false" do
      resource.batched_export_settings = {enabled: false}
      expect(resource.batched_export_enabled?).to be(false)
    end
  end

  describe "#batched_export_column_selection?" do
    it "defaults to the global configuration" do
      ActiveAdmin::BatchedExport.configure { |config| config.default_column_selection = false }
      expect(resource.batched_export_column_selection?).to be(false)
    end

    it "honors per-resource column_selection: true" do
      resource.batched_export_settings = {column_selection: true}
      expect(resource.batched_export_column_selection?).to be(true)
    end
  end

  describe "#batched_export_batch_size" do
    it "falls back to the global batch size" do
      ActiveAdmin::BatchedExport.configure { |config| config.batch_size = 250 }
      expect(resource.batched_export_batch_size).to eq(250)
    end

    it "uses the per-resource batch size when set" do
      resource.batched_export_settings = {batch_size: 50}
      expect(resource.batched_export_batch_size).to eq(50)
    end
  end

  describe "#batched_export_includes" do
    it "returns configured association preloads" do
      resource.batched_export_settings = {includes: [:customer]}
      expect(resource.batched_export_includes).to eq([:customer])
    end

    it "returns nil when includes is not configured" do
      expect(resource.batched_export_includes).to be_nil
    end
  end

  describe "#batched_export_effective_batch_size" do
    it "clamps the requested batch size to the configured maximum" do
      ActiveAdmin::BatchedExport.configure do |configuration|
        configuration.batch_size = 500
        configuration.max_batch_size = 100
      end
      resource.batched_export_settings = {batch_size: 250}

      expect(resource.batched_export_effective_batch_size).to eq(100)
    end
  end
end
