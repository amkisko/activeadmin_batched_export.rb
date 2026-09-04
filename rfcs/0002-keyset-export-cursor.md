# RFC 0002: Keyset export cursor

- Feature Name: keyset-export-cursor
- Type: Standards Track
- Status: Proposed
- Created: 2026-09-04
- Author: Andrei Makarov
- Stakeholders: project maintainers
- Feedback until: 2026-09-18
- Requires: RFC 0001

## Summary

Batch export walks the filtered collection with a keyset cursor instead of OFFSET `batch_page`. The browser follows `X-Batched-Export-Next` until the header is absent. The walk is not a point-in-time snapshot.

## Motivation

Kaminari OFFSET pages skip, duplicate, or omit rows when the table changes between chunks. `total_batches` captured in workspace HTML can report Ready after a truncated file. Each OFFSET page also COUNT and skip-scans. Operators need a walk that does not repeat already-returned primary keys, and a client that stops on a short last page.

## Guide-level explanation

Workspace remains an HTML GET with `export_format` and no csv, json, or xml format. Meta remains JSON with `export_meta=1`. A batch request uses the export format. The first chunk has no cursor. Later chunks pass `export_cursor` copied from `X-Batched-Export-Next`. CSV column names appear only on the first chunk. Load export always refetches meta for the progress estimate. Cancel keeps an incomplete Blob. JSON chunks concatenate as array text.

Inserts in the already-walked range are omitted. Deletes of already-exported rows do not skip later rows. Concurrent inserts ahead of the remaining walk can still appear.

## Reference-level explanation

A request is a batch when `request.format.symbol` equals the normalized `export_format` among csv, json, and xml, and `export_meta` is absent. Garbage `export_cursor` or a cursor whose field or direction does not match the current ActiveAdmin::OrderClause is 400. `export_columns` present with no resolvable index is 400. Macros run, then `ActiveAdmin::Sanitizer.sanitize` on each cell.

Cursor payload is Base64url JSON `{ f, d, k, s }`: sort field, `asc` or `desc`, primary key, sort value. Time and Date dump as iso8601. Decode casts with `model.type_for_attribute`. Sort field must be a table column on the resource. Custom `order_by` expressions fall back to primary key descending. When the sort field is not the primary key, the walk uses `(sort, pk)` with the same direction on both. Next cursor comes from the last record of a full page. A short or empty page omits the header.

`batched_export_url_for` strips `export_cursor`, `batch_page`, and `export_meta`. `batch_page` is ignored.

## Registrar

Query param: `export_cursor`. Response header: `X-Batched-Export-Next`. Error: `UnresolvableExportColumnsError`.

## Drawbacks

Old clients that send `batch_page` no longer page. Hosts that copied the Stimulus controller must pick up the cursor loop. Keyset still omits inserts behind the cursor and is not an UPDATE snapshot. NULL sort keys are unspecified.

## Rationale and alternatives

Refetching meta and treating 404 as shrink still OFFSET-duplicates on insert. A snapshot table or job needs host storage this gem does not own. File System Access API does not fix skip and dup.

## Prior art

Keyset pagination (seek method) on ordered unique `(sort, pk)` tuples. Kaminari remains for the one COUNT in `export_meta`.

## Unresolved questions

RFC 0003 specifies the freeze table, `max_export_rows`, and NULL-safe sort keys.

## Future possibilities

Background assembly. Indexed `(sort, pk)` operator notes.
