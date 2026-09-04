# frozen_string_literal: true

module ActiveAdmin
  module BatchedExport
    class KeysetPage
      def self.records(relation, model:, field:, direction:, cursor:, limit:)
        scoped = ordered(relation, model: model, field: field, direction: direction)
        scoped = apply_after(scoped, model: model, field: field, direction: direction, cursor: cursor) if cursor
        scoped.limit(limit).to_a
      end

      def self.ordered(relation, model:, field:, direction:)
        table = model.arel_table
        primary_key = model.primary_key.to_s
        primary_key_order = arel_direction(table[primary_key], direction)
        return relation.except(:order).order(primary_key_order) if field == primary_key

        relation.except(:order).order(
          table[field].eq(nil),
          arel_direction(table[field], direction),
          primary_key_order
        )
      end

      def self.next_cursor(records, field:, direction:, primary_key:, limit:, position: nil)
        return nil if records.empty? || records.length < limit

        last_record = records.last
        ExportCursor.encode(
          field: field,
          direction: direction,
          primary_key: last_record.public_send(primary_key),
          sort_value: last_record.public_send(field),
          position: position
        )
      end

      def self.apply_after(relation, model:, field:, direction:, cursor:)
        table = model.arel_table
        primary_key = model.primary_key
        primary_key_value = cast(model, primary_key, cursor.primary_key)
        if field == primary_key.to_s
          return after_primary_key(relation, table[primary_key], primary_key_value, direction)
        end

        after_sort_and_primary_key(
          relation,
          table[field],
          cast(model, field, cursor.sort_value),
          table[primary_key],
          primary_key_value,
          direction
        )
      end

      def self.arel_direction(column, direction)
        (direction == "desc") ? column.desc : column.asc
      end

      def self.after_primary_key(relation, column, value, direction)
        comparator = (direction == "desc") ? :lt : :gt
        relation.where(column.public_send(comparator, value))
      end

      def self.after_sort_and_primary_key(relation, sort_column, sort_value, pk_column, pk_value, direction)
        pk_past = pk_column.public_send((direction == "desc") ? :lt : :gt, pk_value)
        return relation.where(sort_column.eq(nil).and(pk_past)) if sort_value.nil?

        sort_past = sort_column.public_send((direction == "desc") ? :lt : :gt, sort_value)
        relation.where(
          sort_past.and(sort_column.not_eq(nil))
            .or(sort_column.eq(sort_value).and(pk_past))
            .or(sort_column.eq(nil))
        )
      end

      def self.cast(model, name, raw)
        model.type_for_attribute(name).cast(raw)
      end
      private_class_method :apply_after, :arel_direction, :after_primary_key,
        :after_sort_and_primary_key, :cast
    end
  end
end
