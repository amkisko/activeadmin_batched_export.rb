# frozen_string_literal: true

module ActiveAdmin
  module BatchedExport
    module Install
      module_function

      def call
        ActiveAdmin.application.namespaces.each do |namespace|
          namespace.resources.each do |config|
            next if config.is_a?(ActiveAdmin::Page)
            next unless config.batched_export_enabled?
            next unless config.controller.action_methods.include?("index")

            changed = false
            unless config.collection_actions.any? { |action| action.name.to_sym == :batched_export }
              config.collection_actions << ActiveAdmin::ControllerAction.new(:batched_export, method: :get)
              changed = true
            end

            controller = config.controller
            unless controller.included_modules.include?(ControllerMethods)
              controller.include(ControllerMethods)
              changed = true
            end

            controller.clear_action_methods! if changed
          end
        end
      end
    end
  end
end
