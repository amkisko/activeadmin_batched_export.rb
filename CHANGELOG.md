# CHANGELOG

## Unreleased

- Return 406 when a csv, json, or xml `batched_export` request is not JSON metadata and not a matching-format batch.

## 0.3.0 (2026-09-04)

- BREAKING: Walk export batches with `export_cursor` and `X-Batched-Export-Next` instead of OFFSET `batch_page`. Hosts that copied the Stimulus controller must pick up the new loop.
- Freeze filtered ids when table `active_admin_batched_export_snapshot_rows` exists (`export_snapshot`, `X-Batched-Export-Snapshot`). Without the table, batches keep walking a live keyset.
- Add `max_export_rows` (nil = unlimited). A COUNT over the cap is 400 on the first batch; meta still returns 200 with `over_max`.
- Sort NULL keys last in both directions.
- Always refetch export meta before load. Stop on a short last page. Concatenate JSON chunks as one array. Cancel keeps an incomplete Blob.
- Return 400 when `export_columns` resolve to no columns.

## 0.2.0 (2026-07-14)

- Treat a per-resource `batched_export` DSL call as enablement; `enabled: true` is no longer required when opting in per resource.
- Guard download format links on `batched_export_enabled?` and fall back to standard ActiveAdmin format links when export is disabled.
- Default batched export to opt-in (`default_enabled = false`).
- Register batched export routes on ActiveAdmin load and after ActiveAdmin routes are drawn so path helpers exist for enabled resources.
- Prepend batched export view overrides ahead of ActiveAdmin defaults so the shared download partial is actually used.

## 0.1.0 (2026-07-10)

- Initial public release of batched ActiveAdmin export workspace.
- Batched CSV, JSON, and XML export with Stimulus client assembly.
- Configurable styles, batch size, filename proc, and per-resource `batched_export` DSL.
- Export column macros: named catalog, built-ins, and Ruby proc support.
- Overridable view partials and download link routing.
