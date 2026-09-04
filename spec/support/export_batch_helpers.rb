# frozen_string_literal: true

module ExportBatchHelpers
  BatchResponse = Struct.new(:body, :headers)

  def export_batch_response
    BatchResponse.new(
      response.body.dup,
      {
        "X-Batched-Export-Next" => response.headers["X-Batched-Export-Next"],
        "X-Batched-Export-Snapshot" => response.headers["X-Batched-Export-Snapshot"]
      }
    )
  end
end
