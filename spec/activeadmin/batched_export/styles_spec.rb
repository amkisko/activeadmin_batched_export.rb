# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveAdmin::BatchedExport::Styles do
  it "merges custom class overrides" do
    styles = described_class.new(primary_button: "btn btn-primary")
    expect(styles[:primary_button]).to eq("btn btn-primary")
    expect(styles[:card]).to include("rounded")
  end

  it "exposes a visible cancel button class" do
    expect(described_class.new[:cancel_button]).to include("rounded")
    expect(described_class.new[:cancel_button]).not_to include("hidden")
  end
end
