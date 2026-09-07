# frozen_string_literal: true

require "activeadmin/batched_export/chunk_renderer"
require "activeadmin/batched_export/errors"
require "activeadmin/batched_export/export_cursor"
require "activeadmin/batched_export/keyset_page"
require "activeadmin/batched_export/snapshot_page"

module ActiveAdmin
  module BatchedExport
    module ControllerMethods
      extend ActiveSupport::Concern
      include ChunkRenderer

      def batched_export
        authorize! ActiveAdmin::Authorization::READ, active_admin_config.resource_class
        export_format = normalized_export_format
        return if export_format.nil?

        if request.format.json? && params[:export_meta].present?
          ensure_batch_download_format_allowed!(export_format)
          return render(json: batched_export_meta(export_format))
        end

        return render_export_batch(export_format) if export_batch_request?(export_format)
        return head(:not_acceptable) if %i[csv json xml].include?(request.format.symbol)

        render_export_workspace(export_format)
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

      def export_batch_request?(export_format)
        %i[csv json xml].include?(request.format.symbol) &&
          request.format.symbol == export_format &&
          params[:export_meta].blank?
      end

      def render_export_batch(export_format)
        ensure_batch_download_format_allowed!(export_format)
        refuse_over_max_export_rows! if starting_export_walk?
        field, direction = batched_export_sort_pair
        cursor = decode_export_cursor(field: field, direction: direction)
        page = snapshot_export_page(field: field, direction: direction, cursor: cursor)
        response.set_header(ExportCursor::NEXT_HEADER, page.next_cursor) if page.next_cursor
        response.set_header(SnapshotPage::HEADER, page.snapshot_token) if page.snapshot_token
        body = batched_export_batch_body(export_format, page.records, first_page: page.first_page)
        render(plain: body, content_type: batch_content_type(export_format))
      rescue ExportCursor::Invalid
        render(plain: "Invalid export cursor", status: :bad_request)
      rescue InvalidExportSnapshotError
        render(
          plain: I18n.t("active_admin.batched_export_page.unavailable_session"),
          status: :bad_request
        )
      rescue ExportTooLargeError
        render(
          plain: I18n.t("active_admin.batched_export_page.over_max_rows"),
          status: :bad_request
        )
      rescue UnresolvableExportColumnsError
        render(
          plain: I18n.t("active_admin.batched_export_page.select_at_least_one_column"),
          status: :bad_request
        )
      rescue ExportMacroCatalog::UnknownMacroError
        render(
          plain: I18n.t("active_admin.batched_export_page.unknown_macro"),
          status: :unprocessable_content
        )
      end

      def render_export_workspace(export_format)
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

      def batched_export_url_for(request_format:, extra_params: {})
        query = request.query_parameters.except(
          :format, :commit, :page, :batch_page, :export_meta, :export_cursor, :export_snapshot
        )
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
        cap = BatchedExport.config.max_export_rows
        {
          export_format: export_format,
          total_count: total_count,
          total_batches: total_batches,
          batch_size: effective_batch_size,
          filename: export_filename(export_format),
          large_export: total_count >= BatchedExport.config.large_export_row_threshold,
          over_max: cap.present? && total_count > cap,
          max_export_rows: cap
        }
      end

      def export_filtered_count
        paginate(find_collection(except: [:pagination]), 1, effective_batch_size).total_count
      end

      def starting_export_walk?
        params[:export_snapshot].blank? && params[:export_cursor].blank?
      end

      def refuse_over_max_export_rows!
        cap = BatchedExport.config.max_export_rows
        return if cap.blank?

        raise ExportTooLargeError if export_filtered_count > cap
      end

      def export_filename(format_symbol)
        filename_proc = active_admin_config.batched_export_filename_proc
        if filename_proc
          return filename_proc.call(active_admin_config, format_symbol, self)
        end

        base = resource_collection_name.to_s.tr("_", "-")
        "#{base}-#{Time.zone.now.to_date}.#{format_symbol}"
      end

      def batch_content_type(export_format)
        case export_format
        when :csv then "text/csv; charset=utf-8"
        when :json then "application/json; charset=utf-8"
        when :xml then "application/xml; charset=utf-8"
        else "text/plain; charset=utf-8"
        end
      end

      def batched_export_sort_pair
        model = active_admin_config.resource_class
        order_param = params[:order].presence || active_admin_config.sort_order
        clause = ActiveAdmin::OrderClause.new(active_admin_config, order_param)
        field = clause.valid? ? clause.field.to_s.split(".").last : nil
        if field && model.column_names.include?(field)
          [field, clause.order.to_s]
        else
          [model.primary_key.to_s, "desc"]
        end
      end

      def decode_export_cursor(field:, direction:)
        raw = params[:export_cursor]
        return nil if raw.blank?

        cursor = ExportCursor.decode(raw)
        unless cursor.field == field && cursor.direction == direction
          raise ExportCursor::Invalid, "mismatch"
        end

        cursor
      end

      def snapshot_export_page(field:, direction:, cursor:)
        SnapshotPage.fetch(
          export_collection,
          model: active_admin_config.resource_class,
          field: field,
          direction: direction,
          cursor: cursor,
          snapshot_param: params[:export_snapshot],
          limit: effective_batch_size
        )
      end

      def export_collection
        collection = find_collection(except: [:pagination])
        includes_list = active_admin_config.batched_export_includes
        includes_list.present? ? collection.includes(includes_list) : collection
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
        raise UnresolvableExportColumnsError if resolved.empty?

        resolved
      end
    end
  end
end
