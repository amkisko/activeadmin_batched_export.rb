# frozen_string_literal: true

module ActiveAdmin
  module BatchedExport
    class UnresolvableExportColumnsError < StandardError; end
    class ExportTooLargeError < StandardError; end
    class InvalidExportSnapshotError < StandardError; end
  end
end
