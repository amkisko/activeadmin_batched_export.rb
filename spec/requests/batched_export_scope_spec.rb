# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Batched export collection scope", type: :request do
  before do
    OwnedNote.delete_all
    OwnedNote.create!(owner_key: "alice", body: "alice-only-note")
    OwnedNote.create!(owner_key: "bob", body: "bob-only-note")
  end

  it "does not include another owner's rows in the export" do
    get batched_export_admin_owned_notes_path(
      format: :csv,
      export_format: "csv"
    ), headers: {"X-Export-Owner" => "alice"}

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("alice-only-note")
    expect(response.body).not_to include("bob-only-note")
  end

  it "exports no rows when the owner header is absent" do
    get batched_export_admin_owned_notes_path(
      format: :csv,
      export_format: "csv"
    )

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("alice-only-note")
    expect(response.body).not_to include("bob-only-note")
  end
end
