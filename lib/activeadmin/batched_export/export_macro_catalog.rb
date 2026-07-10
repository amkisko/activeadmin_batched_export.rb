# frozen_string_literal: true

require "digest"
require "active_support/core_ext/object/blank"

module ActiveAdmin
  module BatchedExport
    class ExportMacroCatalog
      class UnknownMacroError < KeyError; end

      def self.register(name, callable, registry: nil)
        key = name.to_sym
        raise ArgumentError, "macro must respond to :call" unless callable.respond_to?(:call)

        target = registry || global_registry
        target[key] = callable
      end

      def self.fetch(name, registry: nil)
        key = name.to_sym
        target = registry || global_registry
        target[key] || built_ins[key] || raise(UnknownMacroError, "unknown export macro: #{name}")
      end

      def self.resolve(name, registry: nil)
        macro = name
        return macro if macro.respond_to?(:call)

        fetch(macro, registry: registry)
      end

      def self.global_registry
        @global_registry ||= {}
      end

      def self.built_ins
        @built_ins ||= {
          mask_email: lambda { |value, _record, _column|
            next nil if value.blank?

            local, domain = value.to_s.split("@", 2)
            next "[redacted]" if local.blank? || domain.blank?

            visible = local[0, 2] || ""
            "#{visible}***@#{domain}"
          },
          mask_phone: lambda { |value, _record, _column|
            next nil if value.blank?

            digits = value.to_s.gsub(/\D/, "")
            next "[redacted]" if digits.length < 4

            "#{"*" * (digits.length - 4)}#{digits[-4, 4]}"
          },
          truncate_middle: lambda { |value, _record, _column|
            next nil if value.blank?

            text = value.to_s
            next text if text.length <= 8

            "#{text[0, 3]}…#{text[-3, 3]}"
          },
          hash_identifier: lambda { |value, _record, _column|
            next nil if value.blank?

            Digest::SHA256.hexdigest(value.to_s)[0, 12]
          },
          redact: lambda { |_value, _record, _column|
            "[redacted]"
          }
        }.freeze
      end

      private_class_method :built_ins
    end
  end
end
