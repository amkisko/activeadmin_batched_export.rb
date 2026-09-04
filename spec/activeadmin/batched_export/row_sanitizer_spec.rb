# frozen_string_literal: true

require "rails_helper"
require "activeadmin/batched_export/row_sanitizer"

RSpec.describe ActiveAdmin::BatchedExport::RowSanitizer do
  it "prefixes formula characters that macros reintroduce" do
    expect(described_class.apply(["=CMD()", "+1", "ok"])).to eq(["'=CMD()", "'+1", "ok"])
  end
end
