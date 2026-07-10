# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveAdmin::BatchedExport::Styles do
  it "merges custom class overrides" do
    styles = described_class.new(primary_button: "btn btn-primary")
    expect(styles[:primary_button]).to eq("btn btn-primary")
    expect(styles[:card]).to include("rounded")
  end
end
