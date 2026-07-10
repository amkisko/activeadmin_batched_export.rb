# frozen_string_literal: true

module ActiveAdmin
  module BatchedExport
    class ExportMacroResolver
      MAX_MACROS = 50

      def self.apply(row:, columns:, resource:, resource_settings:, registry:)
        new(
          row: row,
          columns: columns,
          resource: resource,
          resource_settings: resource_settings,
          registry: registry
        ).apply
      end

      def initialize(row:, columns:, resource:, resource_settings:, registry:)
        @row = row.dup
        @columns = columns
        @resource = resource
        @resource_settings = resource_settings || {}
        @registry = registry
        @resource_macros = normalize_macro_map(@resource_settings[:macros] || @resource_settings["macros"])
      end

      def apply
        @columns.each_with_index do |column, index|
          macro = macro_for(column)
          next if macro.nil?

          @row[index] = macro.call(@row[index], @resource, column)
        end
        @row
      end

      private

      def macro_for(column)
        explicit = column.options[:macro] if column.respond_to?(:options)
        return resolve_macro(explicit) unless explicit.nil?

        keys = macro_lookup_keys(column)
        keys.each do |key|
          mapped = @resource_macros[key]
          return resolve_macro(mapped) unless mapped.nil?
        end

        nil
      end

      def macro_lookup_keys(column)
        keys = []
        keys << column.data if column.respond_to?(:data) && column.data.is_a?(Symbol)
        keys << column.name if column.respond_to?(:name)
        keys.map { |key| key.to_s.downcase.tr(" ", "_") }.uniq
      end

      def normalize_macro_map(macros)
        return {} unless macros.is_a?(Hash)
        raise ArgumentError, "too many export macros" if macros.size > MAX_MACROS

        macros.each_with_object({}) do |(key, value), normalized|
          normalized[key.to_s.downcase.tr(" ", "_")] = value
        end
      end

      def resolve_macro(macro)
        ExportMacroCatalog.resolve(macro, registry: @registry)
      end
    end
  end
end
