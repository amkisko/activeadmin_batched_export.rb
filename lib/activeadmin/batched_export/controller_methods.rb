# frozen_string_literal: true

require "builder"
require "csv"

module ActiveAdmin
  module BatchedExport
    module ControllerMethods
      extend ActiveSupport::Concern

      def batched_export
        authorize! ActiveAdmin::Authorization::READ, active_admin_config.resource_class
        export_format = normalized_export_format
        return if export_format.nil?

        if request.format.json? && params[:export_meta].present?
          ensure_batch_download_format_allowed!(export_format)
          return render(json: batched_export_meta(export_format))
        end

        batch_page = params[:batch_page].to_i
        if batch_page.positive?
          if request.format.symbol != export_format
            head :not_acceptable
            return
          end
          ensure_batch_download_format_allowed!(export_format)
          page = page_relation(batch_page)
          if page.out_of_range?
            head :not_found
            return
          end
          begin
            body = batched_export_batch_body(export_format, batch_page, page: page)
          rescue ExportMacroCatalog::UnknownMacroError
            return render(
              plain: I18n.t("active_admin.batched_export_page.unknown_macro"),
              status: :unprocessable_content
            )
          end
          return render(plain: body, content_type: batch_content_type(export_format))
        end

        ensure_batch_download_format_allowed!(export_format)
        @batched_export_format = export_format
        @batched_export_meta_url = batched_export_url_for(
          request_format: :json,
          extra_params: {"export_meta" => "1", "export_format" => export_format.to_s}
        )
        @batched_export_batch_base_url = batched_export_url_for(
          request_format: export_format,
          extra_params: {"export_format" => export_format.to_s}
        )
        @batched_export_styles = BatchedExport.styles
        @batched_export_stimulus_controller = BatchedExport.config.stimulus_controller
        assign_batched_export_workspace_extras!(export_format)
        render "active_admin/batched_export/workspace", layout: "active_admin"
      end

      private

      def normalized_export_format
        format_name = params[:export_format].to_s.downcase
        format_name = "csv" if format_name.blank?
        unless %w[csv xml json].include?(format_name)
          render(plain: "Invalid export format", status: :bad_request)
          return nil
        end
        format_name.to_sym
      end

      def batched_export_url_for(request_format:, extra_params: {})
        query = request.query_parameters.except(:format, :commit, :page, :batch_page, :export_meta)
        hash = query.respond_to?(:to_unsafe_h) ? query.to_unsafe_h : query.to_h
        hash = hash.merge(extra_params.stringify_keys)
        url_for(action: :batched_export, format: request_format, params: hash, only_path: true)
      end

      def ensure_batch_download_format_allowed!(format_symbol)
        return if format_symbol == :html

        presenter = active_admin_config.get_page_presenter(:index)
        download_links = (presenter || {}).fetch(:download_links, active_admin_config.namespace.download_links)
        allowed = build_download_formats(download_links)
        unless allowed.include?(format_symbol)
          raise ActiveAdmin::AccessDenied.new(current_active_admin_user, :index)
        end
      end

      def batched_export_meta(export_format)
        base = find_collection(except: [:pagination])
        first_page = paginate(base, 1, effective_batch_size)
        total_count = first_page.total_count
        total_batches = total_count.zero? ? 0 : first_page.total_pages
        {
          export_format: export_format,
          total_count: total_count,
          total_batches: total_batches,
          batch_size: effective_batch_size,
          filename: export_filename(export_format),
          large_export: total_count >= BatchedExport.config.large_export_row_threshold
        }
      end

      def export_filename(format_symbol)
        filename_proc = active_admin_config.batched_export_filename_proc
        if filename_proc
          return filename_proc.call(active_admin_config, format_symbol, self)
        end

        base = resource_collection_name.to_s.tr("_", "-")
        "#{base}-#{Time.zone.now.to_date}.#{format_symbol}"
      end

      def batched_export_batch_body(export_format, batch_page, page: nil)
        case export_format
        when :csv then batched_csv_chunk(batch_page, page: page)
        when :json then batched_json_chunk(batch_page, page: page)
        when :xml then batched_xml_chunk(batch_page, page: page)
        else ""
        end
      end

      def batch_content_type(export_format)
        case export_format
        when :csv then "text/csv; charset=utf-8"
        when :json then "application/json; charset=utf-8"
        when :xml then "application/xml; charset=utf-8"
        else "text/plain; charset=utf-8"
        end
      end

      def batched_csv_chunk(batch_page, page: nil)
        builder = active_admin_config.csv_builder
        options = builder.options.dup
        csv_options = options.except(:encoding_options, :humanize_name, :byte_order_mark)
        columns = batched_export_filter_columns(builder.exec_columns(view_context))
        buffer = +""
        byte_order_mark = options[:byte_order_mark]
        buffer << byte_order_mark if batch_page == 1 && byte_order_mark
        if batch_page == 1 && options.fetch(:column_names, true)
          header_line = columns.map do |column|
            ActiveAdmin::Sanitizer.sanitize(builder.send(:encode, column.name, options))
          end
          buffer << CSV.generate_line(header_line, **csv_options)
        end
        paginated_export_rows(batch_page, page: page) do |resource|
          row = builder.build_row(resource, columns, options)
          row = apply_export_macros(row, columns, resource)
          buffer << CSV.generate_line(row, **csv_options)
        end
        buffer
      end

      def batched_json_chunk(batch_page, page: nil)
        builder = active_admin_config.csv_builder
        options = builder.options
        columns = batched_export_filter_columns(builder.exec_columns(view_context))
        names = columns.map(&:name)
        rows = []
        paginated_export_rows(batch_page, page: page) do |resource|
          row = apply_export_macros(builder.build_row(resource, columns, options), columns, resource)
          rows << names.zip(row).to_h
        end
        rows.to_json
      end

      def batched_xml_chunk(batch_page, page: nil)
        builder = active_admin_config.csv_builder
        options = builder.options
        columns = batched_export_filter_columns(builder.exec_columns(view_context))
        xml = Builder::XmlMarkup.new(indent: 0)
        paginated_export_rows(batch_page, page: page) do |resource|
          row = apply_export_macros(builder.build_row(resource, columns, options), columns, resource)
          xml.batch do
            xml.record do
              columns.each_with_index do |column, index|
                xml.field("name" => column.name) { xml.text!(row[index].to_s) }
              end
            end
          end
        end
        xml.target!
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

      def paginated_export_rows(batch_page, page: nil)
        (page || page_relation(batch_page)).each do |resource|
          yield apply_decorator(resource)
        end
      end

      def page_relation(page)
        collection = find_collection(except: [:pagination])
        includes_list = active_admin_config.batched_export_includes
        collection = collection.includes(includes_list) if includes_list.present?
        paginate(collection, page, effective_batch_size)
      end

      def effective_batch_size
        active_admin_config.batched_export_effective_batch_size
      end

      def assign_batched_export_workspace_extras!(export_format)
        @batched_export_preview = batched_export_meta(export_format)
        @batched_export_csv_columns =
          if active_admin_config.batched_export_column_selection?
            batched_export_csv_column_metadata
          else
            []
          end
        summary_chain = scoped_collection
        summary_chain = apply_authorization_scope(summary_chain)
        ransack_search = summary_chain.ransack(
          params[:q] || {},
          auth_object: active_admin_authorization
        )
        @batched_export_active_filters =
          ActiveAdmin::Filters::Active.new(active_admin_config, ransack_search)
        @batched_export_sort_description = batched_export_sort_description
        @batched_export_large_export = @batched_export_preview[:large_export]
      end

      def batched_export_sort_description
        order_param = params[:order].presence || active_admin_config.sort_order
        clause = ActiveAdmin::OrderClause.new(active_admin_config, order_param)
        return order_param.to_s.tr("_", " ").strip.presence || "—" unless clause.valid?

        attribute = active_admin_config.resource_class.human_attribute_name(clause.field)
        direction =
          if clause.order == "desc"
            I18n.t("active_admin.batched_export_page.sort_descending")
          else
            I18n.t("active_admin.batched_export_page.sort_ascending")
          end
        "#{attribute} — #{direction}"
      end

      def batched_export_csv_column_metadata
        builder = active_admin_config.csv_builder
        columns = builder.exec_columns(view_context)
        columns.each_with_index.map do |column, index|
          {index: index, label: column.name}
        end
      end

      def batched_export_selected_indices
        raw = params[:export_columns].presence || params[:export_column_indices]
        return [] if raw.blank?

        Array(raw).filter_map { |value| Integer(value, exception: false) }.select { |index| index >= 0 }
      end

      def batched_export_filter_columns(columns)
        indices = batched_export_selected_indices
        return columns if indices.empty?

        resolved = indices.filter_map { |index| columns[index] }
        resolved.presence || columns
      end
    end
  end
end
