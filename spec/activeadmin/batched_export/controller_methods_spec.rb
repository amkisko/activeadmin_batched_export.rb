# frozen_string_literal: true

require "spec_helper"
require "active_support/concern"
require "active_support/hash_with_indifferent_access"
require "activeadmin/batched_export/controller_methods"

RSpec.describe ActiveAdmin::BatchedExport::ControllerMethods do
  let(:controller) do
    Class.new do
      include ActiveAdmin::BatchedExport::ControllerMethods

      attr_reader :params

      def params=(value)
        @params = ActiveSupport::HashWithIndifferentAccess.new(value || {})
      end

      def initialize(params = {})
        self.params = params
      end
    end.new
  end

  describe "#batched_export_selected_indices" do
    it "returns empty array when export_columns is blank" do
      controller.params = {}
      expect(controller.send(:batched_export_selected_indices)).to eq([])
    end

    it "parses export_columns array" do
      controller.params = {"export_columns" => %w[0 2]}
      expect(controller.send(:batched_export_selected_indices)).to eq([0, 2])
    end

    it "ignores invalid and negative indices" do
      controller.params = {"export_columns" => %w[-1 abc 1]}
      expect(controller.send(:batched_export_selected_indices)).to eq([1])
    end
  end

  describe "#batched_export_filter_columns" do
    let(:columns) { %w[a b c].map { |name| double(name: name) } }

    it "returns all columns when no selection" do
      controller.params = {}
      expect(controller.send(:batched_export_filter_columns, columns)).to eq(columns)
    end

    it "returns selected columns by index" do
      controller.params = {"export_columns" => ["2", "0"]}
      expect(controller.send(:batched_export_filter_columns, columns).map(&:name)).to eq(%w[c a])
    end

    it "falls back to all columns when selection resolves empty" do
      controller.params = {"export_columns" => ["99"]}
      expect(controller.send(:batched_export_filter_columns, columns)).to eq(columns)
    end
  end
end
