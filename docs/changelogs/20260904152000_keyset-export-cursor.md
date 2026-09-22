# Keyset export cursor

## Decisions

Batch export walks with export_cursor and X-Batched-Export-Next (RFC-0002) instead of OFFSET batch_page.

Load export always refetches export_meta. Progress total_batches is an estimate. The walk stops on a short last page.

JSON chunks concatenate as array text. Cancel aborts the in-flight fetch and keeps an incomplete Blob when any chunk already arrived.

export_columns that resolve no columns return 400. Macros run, then ActiveAdmin::Sanitizer on each cell.

The walk is not a snapshot. Inserts behind the cursor are omitted.

Later pass: RFC-0003 freeze table on the same branch stores filtered ids on the first batch when that table exists.

## Effects

Request specs cover first-page headers, later pages without headers, invalid cursor 400, unresolvable columns 400, insert and delete between pages, and JSON text concat.

Stimulus, workspace Cancel, locales, README Ruby 3.4+, and custom theme cancel_button were updated in the same pass.

## Next

RFC-0003 freeze table, max_export_rows, and NULL-safe sort keys closed the remaining walk items on this branch.

Hash pepper, rate-limit product, and audit logging stay out of this pass.

## Source

RFC-0002. usr/docs/issues/20260904144900_engineering-audit.md.
