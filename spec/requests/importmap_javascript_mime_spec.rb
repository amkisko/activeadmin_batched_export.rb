# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Importmap JavaScript MIME", type: :request do
  let(:export_module_names) do
    [
      "controllers/activeadmin_batched_export/batched_export_controller",
      "activeadmin_batched_export/chunk_assembly"
    ]
  end

  it "pins export modules on the ActiveAdmin importmap only" do
    expect(Rails.application.importmap.packages.keys).not_to include(*export_module_names)
    expect(ActiveAdmin.importmap.packages.keys).to include(*export_module_names)
  end

  it "serves chunk assembly with a JavaScript media type" do
    chunk_pin = ActiveAdmin.importmap.packages.fetch("activeadmin_batched_export/chunk_assembly")
    get ActionController::Base.helpers.path_to_asset(chunk_pin.path)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/javascript")
  end
end
