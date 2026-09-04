# frozen_string_literal: true

require "base64"
require "json"

module ActiveAdmin
  module BatchedExport
    class ExportCursor
      Invalid = Class.new(StandardError)
      NEXT_HEADER = "X-Batched-Export-Next"

      Payload = Struct.new(:field, :direction, :primary_key, :sort_value, :position)

      def self.encode(field:, direction:, primary_key:, sort_value:, position: nil)
        payload = {
          "f" => field,
          "d" => direction,
          "k" => dump_value(primary_key),
          "s" => dump_value(sort_value)
        }
        payload["p"] = position unless position.nil?
        Base64.urlsafe_encode64(JSON.generate(payload), padding: false)
      end

      def self.decode(raw)
        raise Invalid, "blank" if raw.nil? || raw.to_s.empty?

        payload_from_hash(JSON.parse(Base64.urlsafe_decode64(raw.to_s)))
      rescue ArgumentError, JSON::ParserError, KeyError, TypeError
        raise Invalid
      end

      def self.dump_value(value)
        case value
        when Time, DateTime then value.iso8601(6)
        when Date then value.iso8601
        else value
        end
      end

      def self.payload_from_hash(hash)
        direction = hash.fetch("d")
        raise Invalid, "direction" unless %w[asc desc].include?(direction)

        Payload.new(
          hash.fetch("f").to_s,
          direction,
          hash.fetch("k"),
          hash.fetch("s"),
          hash["p"]
        )
      end
      private_class_method :payload_from_hash
    end
  end
end
