# frozen_string_literal: true

module ActiveAdmin
  module BatchedExport
    class << self
      def config
        require "activeadmin/batched_export/configuration"
        @config ||= Configuration.new
      end

      def configure
        yield config
      end

      def styles
        config.styles
      end

      def install!
        require "activeadmin/batched_export/install"
        Install.call
      end
    end
  end
end
