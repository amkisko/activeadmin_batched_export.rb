# frozen_string_literal: true

require "activeadmin/batched_export/styles"
require "activeadmin/batched_export/export_macro_catalog"

module ActiveAdmin
  module BatchedExport
    class Configuration
      attr_accessor :styles, :batch_size, :max_batch_size, :large_export_row_threshold, :stimulus_controller,
        :default_enabled, :default_column_selection

      def initialize
        @styles = Styles.new
        @batch_size = 1000
        @max_batch_size = 10_000
        @large_export_row_threshold = 25_000
        @stimulus_controller = "activeadmin-batched-export--batched-export"
        @default_enabled = true
        @default_column_selection = true
        @filename_proc = nil
        @registered_macros = {}
      end

      attr_reader :filename_proc, :registered_macros

      def filename_proc=(callable)
        raise ArgumentError, "filename_proc must respond to :call" unless callable.respond_to?(:call)

        @filename_proc = callable
      end

      def register_macro(name, callable)
        ExportMacroCatalog.register(name, callable, registry: @registered_macros)
      end
    end
  end
end
