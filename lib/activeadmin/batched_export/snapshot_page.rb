# frozen_string_literal: true

require "securerandom"
require "activeadmin/batched_export/errors"
require "activeadmin/batched_export/export_cursor"
require "activeadmin/batched_export/keyset_page"
require "activeadmin/batched_export/snapshot_row"

module ActiveAdmin
  module BatchedExport
    class SnapshotPage
      HEADER = "X-Batched-Export-Snapshot"
      INSERT_SLICE = 500
      Page = Struct.new(:records, :snapshot_token, :next_cursor, :first_page)

      def self.fetch(collection, model:, field:, direction:, cursor:, snapshot_param:, limit:)
        if snapshot_param.present?
          resume(collection, model: model, field: field, direction: direction,
            cursor: cursor, snapshot_param: snapshot_param, limit: limit)
        elsif SnapshotRow.available? && cursor.nil?
          freeze_first(collection, model: model, field: field, direction: direction, limit: limit)
        else
          live(collection, model: model, field: field, direction: direction, cursor: cursor, limit: limit)
        end
      end

      def self.freeze_first(collection, model:, field:, direction:, limit:)
        SnapshotRow.expire_stale!(ttl: BatchedExport.config.snapshot_ttl)
        # Full id list in process memory on freeze. Stream into insert_all when that ceiling matters.
        ids = KeysetPage.ordered(collection, model: model, field: field, direction: direction)
          .pluck(model.primary_key)
        return Page.new(records: [], snapshot_token: nil, next_cursor: nil, first_page: true) if ids.empty?

        token = insert_ids(ids, model.name)
        walk(collection, model: model, field: field, direction: direction,
          token: token, after_position: 0, limit: limit, first_page: true)
      end

      def self.resume(collection, model:, field:, direction:, cursor:, snapshot_param:, limit:)
        raise InvalidExportSnapshotError unless SnapshotRow.available?
        raise InvalidExportSnapshotError if cursor.nil? || cursor.position.nil?

        token = authentic_token(snapshot_param, model.name)
        walk(collection, model: model, field: field, direction: direction,
          token: token, after_position: cursor.position, limit: limit, first_page: false)
      end

      def self.live(collection, model:, field:, direction:, cursor:, limit:)
        records = KeysetPage.records(
          collection, model: model, field: field, direction: direction, cursor: cursor, limit: limit
        )
        Page.new(
          records: records,
          snapshot_token: nil,
          next_cursor: KeysetPage.next_cursor(
            records, field: field, direction: direction, primary_key: model.primary_key, limit: limit
          ),
          first_page: cursor.nil?
        )
      end

      def self.insert_ids(ids, resource_type)
        token = SecureRandom.urlsafe_base64(32)
        created_at = Time.current
        ids.each_slice(INSERT_SLICE).with_index do |slice, slice_index|
          SnapshotRow.insert_all(slice.each_with_index.map { |record_id, offset|
            {
              token: token, resource_type: resource_type, record_id: record_id,
              position: (slice_index * INSERT_SLICE) + offset + 1, created_at: created_at
            }
          })
        end
        token
      end

      def self.authentic_token(raw, resource_type)
        anchor = SnapshotRow.where(token: raw).order(:position).first
        raise InvalidExportSnapshotError if anchor.nil?
        raise InvalidExportSnapshotError if SnapshotRow.expired?(anchor.created_at, ttl: BatchedExport.config.snapshot_ttl)
        raise InvalidExportSnapshotError unless anchor.resource_type == resource_type

        anchor.token
      end

      def self.walk(collection, model:, field:, direction:, token:, after_position:, limit:, first_page:)
        records, consumed = fill_live(collection, model: model, token: token,
          after_position: after_position, limit: limit)
        if SnapshotRow.remaining_after?(token, consumed) && records.length == limit
          return Page.new(
            records: records, snapshot_token: token, first_page: first_page,
            next_cursor: KeysetPage.next_cursor(
              records, field: field, direction: direction,
              primary_key: model.primary_key, limit: limit, position: consumed
            )
          )
        end

        SnapshotRow.delete_token!(token)
        Page.new(records: records, snapshot_token: nil, next_cursor: nil, first_page: first_page)
      end

      def self.fill_live(collection, model:, token:, after_position:, limit:)
        live = []
        consumed = after_position
        position = after_position
        loop do
          window = SnapshotRow.window_after(token, position, limit)
          break if window.empty?

          found = live_by_id(collection, model.primary_key, window)
          consumed = append_live(window, found, live, limit)
          break if live.length == limit

          position = window.last.position
        end
        [live, consumed]
      end

      def self.live_by_id(collection, primary_key, rows)
        collection.where(primary_key => rows.map(&:record_id))
          .index_by { |record| record.public_send(primary_key).to_i }
      end

      def self.append_live(window, found, live, limit)
        consumed = nil
        window.each do |row|
          consumed = row.position
          record = found[row.record_id.to_i]
          next unless record

          live << record
          break if live.length == limit
        end
        consumed
      end
      private_class_method :freeze_first, :resume, :live, :insert_ids, :authentic_token,
        :walk, :fill_live, :live_by_id, :append_live
    end
  end
end
