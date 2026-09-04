# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Batched export macro errors", type: :request do
  before do
    MacroProbe.delete_all
    MacroProbe.create!(name: "probe")
  end

  it "returns unprocessable entity when a column references an unknown macro" do
    get batched_export_admin_macro_probes_path(
      format: :csv,
      export_format: "csv"
    )

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Unknown export macro")
  end
end
