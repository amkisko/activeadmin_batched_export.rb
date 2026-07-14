# frozen_string_literal: true

module ActiveAdmin
  module BatchedExport
    module ResourceSettings
      def batched_export_settings
        @batched_export_settings ||= {}
      end

      def batched_export_settings=(value)
        @batched_export_settings = value || {}
      end

      def batched_export_configured?
        @batched_export_configured == true
      end

      def batched_export_configured=(value)
        @batched_export_configured = value
      end

      def batched_export_enabled?
        settings = batched_export_settings
        if settings.key?(:enabled) || settings.key?("enabled")
          return settings[:enabled] != false && settings["enabled"] != false
        end

        return true if batched_export_configured?

        BatchedExport.config.default_enabled
      end

      def batched_export_column_selection?
        settings = batched_export_settings
        if settings.key?(:column_selection) || settings.key?("column_selection")
          return settings[:column_selection] != false && settings["column_selection"] != false
        end

        BatchedExport.config.default_column_selection
      end

      def batched_export_batch_size
        batched_export_settings[:batch_size] ||
          batched_export_settings["batch_size"] ||
          BatchedExport.config.batch_size
      end

      def batched_export_effective_batch_size
        requested = batched_export_batch_size
        maximum = BatchedExport.config.max_batch_size
        [requested, maximum].min
      end

      def batched_export_includes
        settings = batched_export_settings
        settings[:includes] || settings["includes"]
      end

      def batched_export_filename_proc
        batched_export_settings[:filename] ||
          batched_export_settings["filename"] ||
          BatchedExport.config.filename_proc
      end
    end

    module ResourceDSL
      def batched_export(**options)
        config.batched_export_configured = true
        config.batched_export_settings = options
      end
    end
  end
end

ActiveAdmin::Resource.include(ActiveAdmin::BatchedExport::ResourceSettings)
ActiveAdmin::ResourceDSL.include(ActiveAdmin::BatchedExport::ResourceDSL)
