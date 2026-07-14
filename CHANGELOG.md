# CHANGELOG

## Unreleased

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
