# frozen_string_literal: true

module ActiveAdmin
  module BatchedExport
    module RowSanitizer
      def self.apply(row)
        row.map { |cell| ActiveAdmin::Sanitizer.sanitize(cell) }
      end
    end
  end
end
