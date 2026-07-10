# frozen_string_literal: true

module ActiveAdmin
  module BatchedExport
    class Styles
      DEFAULTS = {
        workspace: "mx-auto max-w-2xl space-y-6 py-8",
        card: "space-y-2 rounded border border-gray-200 bg-white p-4 dark:border-gray-700 dark:bg-gray-900/40",
        card_title: "text-base font-semibold text-gray-900 dark:text-gray-100",
        table: "w-full border-collapse text-sm",
        table_body: "align-top",
        table_row: "border-b border-gray-100 dark:border-gray-800",
        table_header: "w-44 py-2 pr-4 text-left font-medium text-gray-600 dark:text-gray-400",
        table_cell: "py-2 text-gray-900 dark:text-gray-100",
        table_cell_mono: "py-2 font-mono text-sm text-gray-900 dark:text-gray-100",
        hint: "text-sm text-gray-600 dark:text-gray-400",
        column_grid: "grid max-h-[min(70vh,48rem)] grid-cols-1 gap-2 overflow-y-auto sm:grid-cols-2",
        column_label: "flex cursor-pointer items-start gap-2 text-sm text-gray-900 dark:text-gray-100",
        column_checkbox: "mt-0.5",
        heading: "text-lg font-semibold",
        progress_wrap: "hidden space-y-3 rounded border border-gray-200 p-4 dark:border-gray-700",
        progress_bar: "h-2 w-full",
        progress_status_row: "flex justify-between text-sm",
        error: "hidden text-sm text-red-600",
        warning: "text-sm text-amber-800 dark:text-amber-300",
        actions: "flex flex-wrap gap-3",
        primary_button: "rounded bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50",
        secondary_button: "hidden rounded border border-gray-300 px-4 py-2 text-sm font-medium hover:bg-gray-50 disabled:opacity-50 dark:border-gray-600 dark:hover:bg-gray-800",
        back_link: "inline-flex items-center text-sm text-blue-600 hover:underline"
      }.freeze

      def initialize(overrides = {})
        @classes = DEFAULTS.merge(overrides)
      end

      def [](key)
        @classes.fetch(key)
      end

      def merge(overrides)
        self.class.new(@classes.merge(overrides))
      end
    end
  end
end
