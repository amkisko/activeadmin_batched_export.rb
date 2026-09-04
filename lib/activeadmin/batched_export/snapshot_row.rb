# frozen_string_literal: true

require "active_record"

module ActiveAdmin
  module BatchedExport
    class SnapshotRow < ::ActiveRecord::Base
      self.table_name = "active_admin_batched_export_snapshot_rows"
      self.record_timestamps = false

      def self.available?
        table_exists?
      end

      def self.expire_stale!(ttl:)
        # Global sweep on freeze start. Upgrade to a per-token job when volume matters.
        where("created_at < ?", cutoff(ttl)).delete_all
      end

      def self.expired?(created_at, ttl:)
        created_at < cutoff(ttl)
      end

      def self.cutoff(ttl)
        ttl.respond_to?(:ago) ? ttl.ago : Time.current - ttl
      end

      def self.window_after(token, position, limit)
        where(token: token).where("position > ?", position).order(:position).limit(limit).to_a
      end

      def self.remaining_after?(token, position)
        where(token: token).where("position > ?", position).exists?
      end

      def self.delete_token!(token)
        where(token: token).delete_all
      end
    end
  end
end
