# frozen_string_literal: true

module ActiveAdmin
  module BatchedExport
    class Engine < ::Rails::Engine
      engine_name "activeadmin_batched_export"

      initializer "activeadmin_batched_export.load_lib" do
        require "activeadmin/batched_export"
        require "activeadmin/batched_export/styles"
        require "activeadmin/batched_export/export_macro_catalog"
        require "activeadmin/batched_export/export_macro_resolver"
        require "activeadmin/batched_export/configuration"
        require "activeadmin/batched_export/resource_extension"
        require "activeadmin/batched_export/controller_methods"
        require "activeadmin/batched_export/install"
      end

      initializer "activeadmin_batched_export.assets" do |app|
        assets_path = root.join("app/assets")
        app.config.importmap.cache_sweepers << assets_path.join("controllers") if app.config.respond_to?(:importmap)
      end

      initializer "activeadmin_batched_export.importmap", after: :load_config_initializers do
        next unless Rails.application.respond_to?(:importmap) && Rails.application.importmap

        pin_controller = proc do |importmap|
          importmap.pin "controllers/activeadmin_batched_export/batched_export_controller",
            to: "activeadmin_batched_export/batched_export_controller.js"
        end

        Rails.application.importmap.draw(&pin_controller)
        ActiveAdmin.importmap.draw(&pin_controller) if defined?(ActiveAdmin)
      end

      initializer "activeadmin_batched_export.i18n" do
        I18n.load_path << root.join("config/locales/activeadmin_batched_export.en.yml")
      end

      initializer "activeadmin_batched_export.view_overrides", after: "activeadmin_batched_export.load_lib" do
        views_path = root.join("app/views").to_s

        ActiveSupport.on_load(:active_admin_controller) do
          prepend_view_path(views_path)
        end

        if defined?(ActiveAdmin::BaseController)
          ActiveAdmin::BaseController.prepend_view_path(views_path)
        end
      end

      initializer "activeadmin_batched_export.after_load", after: :load_config_initializers do
        next unless defined?(ActiveAdmin) && ActiveAdmin.respond_to?(:after_load)

        ActiveAdmin.after_load do
          ActiveAdmin::BatchedExport::Install.call if defined?(ActiveAdmin::BatchedExport::Install)
        end
      end

      initializer "activeadmin_batched_export.install", after: "active_admin.routes" do
        ActiveAdmin::BatchedExport::Install.call if defined?(ActiveAdmin)
      end

      config.to_prepare do
        ActiveAdmin::BatchedExport::Install.call if defined?(ActiveAdmin)
      end
    end
  end
end
