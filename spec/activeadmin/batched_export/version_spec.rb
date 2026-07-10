# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveAdmin::BatchedExport do
  it "defines a semver version" do
    expect(described_class::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
