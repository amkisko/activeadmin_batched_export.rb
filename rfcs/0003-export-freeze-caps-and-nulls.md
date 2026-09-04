# RFC 0003: Export freeze, row cap, and NULL-safe keys

- Feature Name: export-freeze-caps-and-nulls
- Type: Standards Track
- Status: Proposed
- Created: 2026-09-04
- Author: Andrei Makarov
- Stakeholders: project maintainers
- Feedback until: 2026-09-18
- Requires: RFC 0001, RFC 0002

## Summary

When the freeze table exists, the first batch stores the filtered primary keys in NULL-safe order and later batches walk that list by position. Hosts may set `max_export_rows` to refuse an over-cap COUNT. Sort keys treat SQL NULL as last in both directions.

## Motivation

RFC 0002 walks live rows. Inserts ahead of the remaining walk can still appear. NULL comparisons are unknown, so a nullable sort column can skip or repeat. `large_export_row_threshold` only warns. Operators need a freeze of which rows belong to this Load export, a hard row cap, and a portable NULL convention.

## Guide-level explanation

Create table `active_admin_batched_export_snapshot_rows` (token, resource_type, record_id, position, created_at). Meta GET does not freeze. The first batch with no `export_snapshot` freezes ids, returns the first chunk, `X-Batched-Export-Snapshot`, and `X-Batched-Export-Next` when more positions remain. Later chunks send both `export_snapshot` and `export_cursor`. The last short page deletes that freeze.

Cells are live at fetch. Updates after freeze appear. Inserts after freeze do not. Deleted freeze ids are skipped. `scoped_collection` still filters the join.

`max_export_rows` default nil means no cap. When set and COUNT is greater, meta sets `over_max` true and a batch is 400 with operator copy about the allowed maximum. Load export stops before walking.

NULL sort keys sort after every non-null value for both `asc` and `desc`. Custom `order_by` still falls back to primary key descending.

## Reference-level explanation

Freeze ORDER BY is `(sort IS NULL), sort, pk` with the ActiveAdmin direction on sort and pk. After a non-null cursor value `s`, remaining rows are non-nulls past `(s, k)` or any NULL. After a NULL cursor, remaining rows are NULL with pk past `k`. Primary-key-only walks stay non-null comparators.

Cursor payload may include integer `p` (last freeze position). Resume requires a token whose `resource_type` matches the resource, `created_at` within `snapshot_ttl` (default 24 hours), and a cursor with `p`. Garbage or mismatch is 400. Token is not access: records load through `find_collection`.

Cap uses the same COUNT as `export_meta`. Refuse before insert when COUNT exceeds the cap. Sweep expired freeze rows on the next freeze start.

Without the freeze table, RFC 0002 live keyset remains, with this RFC's NULL-safe ORDER BY and seek.

## Registrar

Query param: `export_snapshot`. Response header: `X-Batched-Export-Snapshot`. Config: `max_export_rows`, `snapshot_ttl`. Table: `active_admin_batched_export_snapshot_rows`. Errors: `ExportTooLargeError`, `InvalidExportSnapshotError`. Cursor field: `p`.

## Drawbacks

Hosts must migrate to freeze. First batch writes one row per exported id. Cancel can leave rows until TTL. Live keyset without the table still admits inserts ahead of the remaining walk.

## Rationale and alternatives

Rails.cache avoids a migration but is not durable across cache stores. OFFSET freeze was rejected in RFC 0002. Snapshot of cell values would hide later corrections; id freeze plus live join is the smaller contract. Default unlimited cap avoids breaking hosts.

## Prior art

Seek pagination with NULLS LAST. Export jobs that materialize a key list, then join.

## Unresolved questions

Whether a later RFC covers UUID primary keys, per-token sweep jobs, or hashing the freeze token.

## Future possibilities

Background assembly. Indexed operator notes for `(sort, pk)`.
