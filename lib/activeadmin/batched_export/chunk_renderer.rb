# frozen_string_literal: true

require "builder"
require "csv"
require "activeadmin/batched_export/row_sanitizer"

module ActiveAdmin
  module BatchedExport
    module ChunkRenderer
      def batched_export_batch_body(export_format, records, first_page:)
        case export_format
        when :csv then batched_csv_chunk(records, first_page: first_page)
        when :json then batched_json_chunk(records)
        when :xml then batched_xml_chunk(records)
        else ""
        end
      end

      def batched_csv_chunk(records, first_page:)
        builder = export_builder
        options = builder.options.dup
        csv_options = options.except(:encoding_options, :humanize_name, :byte_order_mark)
        columns = export_columns_for(builder)
        buffer = csv_opening(builder, columns, options, csv_options, first_page)
        each_export_row(records) do |resource|
          row = decorated_export_row(builder, columns, options, resource)
          buffer << CSV.generate_line(row, **csv_options)
        end
        buffer
      end

      def batched_json_chunk(records)
        builder = export_builder
        options = builder.options
        columns = export_columns_for(builder)
        names = columns.map(&:name)
        rows = []
        each_export_row(records) do |resource|
          row = decorated_export_row(builder, columns, options, resource)
          rows << names.zip(row).to_h
        end
        rows.to_json
      end

      def batched_xml_chunk(records)
        builder = export_builder
        options = builder.options
        columns = export_columns_for(builder)
        xml = Builder::XmlMarkup.new(indent: 0)
        each_export_row(records) do |resource|
          append_xml_record(xml, columns, decorated_export_row(builder, columns, options, resource))
        end
        xml.target!
      end

      def sanitize_macro_row(row, columns, resource)
        RowSanitizer.apply(apply_export_macros(row, columns, resource))
      end

      def each_export_row(records)
        records.each { |resource| yield apply_decorator(resource) }
      end

      def apply_export_macros(row, columns, resource)
        ExportMacroResolver.apply(
          row: row,
          columns: columns,
          resource: resource,
          resource_settings: active_admin_config.batched_export_settings,
          registry: merged_macro_registry
        )
      end

      def merged_macro_registry
        BatchedExport.config.registered_macros.merge(ExportMacroCatalog.global_registry)
      end

      def export_builder
        active_admin_config.csv_builder
      end

      def export_columns_for(builder)
        batched_export_filter_columns(builder.exec_columns(view_context))
      end

      def decorated_export_row(builder, columns, options, resource)
        sanitize_macro_row(builder.build_row(resource, columns, options), columns, resource)
      end

      def csv_opening(builder, columns, options, csv_options, first_page)
        buffer = +""
        mark = options[:byte_order_mark]
        buffer << mark if first_page && mark
        return buffer unless first_page && options.fetch(:column_names, true)

        headers = columns.map do |column|
          ActiveAdmin::Sanitizer.sanitize(builder.send(:encode, column.name, options))
        end
        buffer << CSV.generate_line(headers, **csv_options)
      end

      def append_xml_record(xml, columns, row)
        xml.batch do
          xml.record do
            columns.each_with_index do |column, index|
              xml.field("name" => column.name) { xml.text!(row[index].to_s) }
            end
          end
        end
      end
    end
  end
end
