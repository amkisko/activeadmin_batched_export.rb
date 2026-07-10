# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveAdmin::BatchedExport::ExportMacroCatalog do
  describe ".fetch" do
    it "returns built-in mask_email macro" do
      macro = described_class.fetch(:mask_email)
      expect(macro.call("person@example.com", nil, nil)).to eq("pe***@example.com")
    end

    it "raises for unknown macro" do
      expect { described_class.fetch(:missing) }.to raise_error(described_class::UnknownMacroError)
    end
  end

  describe ".register" do
    it "stores custom macros in a registry" do
      registry = {}
      described_class.register(:custom, ->(value, _record, _column) { value.to_s.upcase }, registry: registry)
      expect(registry[:custom].call("abc", nil, nil)).to eq("ABC")
    end
  end
end
