# activeadmin_batched_export

[![Gem Version](https://badge.fury.io/rb/activeadmin_batched_export.svg)](https://badge.fury.io/rb/activeadmin_batched_export) [![Test Status](https://github.com/amkisko/activeadmin_batched_export.rb/actions/workflows/test.yml/badge.svg)](https://github.com/amkisko/activeadmin_batched_export.rb/actions/workflows/test.yml)

Batched CSV, JSON, and XML export workspace for ActiveAdmin 4.

Replaces single long-lived index downloads with a workspace page that loads filtered data in sequential HTTP batches, then offers one client-side file download.

## Requirements

- Ruby 3.2+
- Rails 7.1+
- ActiveAdmin 4.0.0.beta13+
- importmap-rails and Stimulus (ActiveAdmin 4 default)

## Dependencies

Required at runtime:

- `rails` (>= 7.1)
- `activeadmin` (>= 4.0.0.beta13, < 5)
- `importmap-rails`

The host app must load ActiveAdmin with importmap and Stimulus (the ActiveAdmin 4 default). No extra JavaScript build step is required beyond the engine pins.

## Installation

Add to your Gemfile:

```ruby
gem "activeadmin_batched_export"
```

Then:

```bash
bundle install
```

The engine registers routes, views, importmap pins, and install hooks automatically. Optional host overrides go in `config/initializers/activeadmin_batched_export.rb`.

Enable download formats per resource:

```ruby
ActiveAdmin.register Order do
  index download_links: [:csv] do
    # ...
  end

  csv do
    column :id
    column :email
  end
end
```

## Configuration

```ruby
# config/initializers/activeadmin_batched_export.rb
ActiveAdmin::BatchedExport.configure do |config|
  config.batch_size = 1000
  config.max_batch_size = 10_000
  config.large_export_row_threshold = 25_000
  config.stimulus_controller = "activeadmin-batched-export--batched-export"

  config.styles = ActiveAdmin::BatchedExport::Styles.new(
    primary_button: "rounded bg-emerald-600 px-4 py-2 text-white"
  )

  config.filename_proc = lambda do |resource_config, format, controller|
    "#{resource_config.resource_name.plural}-export.#{format}"
  end

  config.register_macro(:company_token, lambda { |value, _record, _column|
    value.to_s[0, 6]
  })
end
```

## Per-resource options

```ruby
ActiveAdmin.register User do
  batched_export column_selection: true, batch_size: 500,
    includes: [:account],
    macros: {email: :mask_email, phone: :mask_phone}

  csv do
    column :id
    column :email, macro: :mask_email
    column :notes, macro: ->(value, _record) { value.present? ? "[redacted]" : nil }
  end
end
```

Call `batched_export` on a resource to enable it. The DSL call itself opts the resource in, so you can wrap it in a condition when enablement should vary. Set `batched_export enabled: false` only when you need to override a global `config.default_enabled = true`. Resources without a `batched_export` call stay off unless `default_enabled` is true.

## Built-in export macros

- `:mask_email`
- `:mask_phone`
- `:truncate_middle`
- `:hash_identifier`
- `:redact`

Register custom macros globally with `config.register_macro` or per resource with `batched_export macros: { ... }`.

## Theme customization

Match the export workspace to your ActiveAdmin 4 design system without forking batch or download logic.

### Style classes

Pass Tailwind utilities or your design-system classes through the initializer:

```ruby
# config/initializers/activeadmin_batched_export.rb
ActiveAdmin::BatchedExport.configure do |config|
  config.styles = ActiveAdmin::BatchedExport::Styles.new(
    card: "rounded-lg border border-slate-200 bg-slate-50 p-6",
    primary_button: "btn btn-primary",
    secondary_button: "btn btn-outline",
    back_link: "link link-primary"
  )
end
```

Override only the keys you need; unset keys keep gem defaults (light and dark Tailwind classes).

Available keys: `workspace`, `card`, `card_title`, `table`, `table_body`, `table_row`, `table_header`, `table_cell`, `table_cell_mono`, `hint`, `column_grid`, `column_label`, `column_checkbox`, `heading`, `progress_wrap`, `progress_bar`, `progress_status_row`, `error`, `warning`, `actions`, `primary_button`, `secondary_button`, `back_link`.

### Override partials

Copy any partial from the gem into `app/views/active_admin/batched_export/` in the host app:

- `workspace.html.erb` — page shell; start here for layout changes
- `_summary.html.erb`
- `_columns.html.erb`
- `_filters.html.erb`
- `_progress.html.erb`
- `_actions.html.erb` — export and back buttons

### Stimulus controller

The engine pins `batched_export_controller` on `ActiveAdmin.importmap`. To replace it, pin your own file and set:

```ruby
ActiveAdmin::BatchedExport.configure do |config|
  config.stimulus_controller = "my-batched-export"
end
```

### Adoption checklist

See [examples/custom_theme/README.md](examples/custom_theme/README.md) for locale overrides and verification steps when adding the gem to another themed admin app.

## Stimulus controller and assets

The engine pins `controllers/activeadmin_batched_export/batched_export_controller` on both the host and ActiveAdmin importmaps. Include the gem asset path in your ActiveAdmin importmap cache sweeper when developing locally.

## How it works

1. Index download links route to `batched_export` instead of synchronous format URLs.
2. Workspace shows filter context, optional column checkboxes, and batch metadata.
3. Stimulus fetches `export_meta` JSON, then each `batch_page` chunk.
4. User saves the assembled Blob locally.

Batched requests limit server memory per request; the browser still holds the full assembled file before save. Very large exports can exhaust tab memory. Tune `batch_size`, `max_batch_size`, and `large_export_row_threshold` for your data width and row counts. The workspace shows a warning when row count reaches the threshold.

Each batch page uses offset pagination on the filtered collection. Later batches can slow down on very large tables; narrowing filters or raising `batch_size` within `max_batch_size` reduces batch count.

JSON and XML exports use the same column definitions as `csv` blocks. JSON batches return arrays of row objects; the client merges them into one array. XML batches return record fragments; the client wraps them in a single `<export>` root. Shapes differ from ActiveAdmin synchronous JSON/XML downloads.

Authorization follows ActiveAdmin `download_links` and `authorize!` on the resource. Disable a format with `index download_links: [:csv]` (or `false` to hide exports). Batch endpoints reject formats not listed on the resource index presenter.

## Development

From the gem root:

```bash
bundle install
bundle exec appraisal install
bundle exec rubocop
bundle exec polyrun parallel-rspec --workers 5 --merge-failures
```

Matrixed Rails versions use [Appraisal](https://github.com/thoughtbot/appraisal): `gemfiles/rails72.gemfile`, `rails8ruby34.gemfile`, and `rails8truffleruby.gemfile`. Run `bundle exec appraisal rspec` to execute RSpec in each gemfile context.

Shared agent guidance is managed with [pray](https://github.com/kiskolabs/pray) via `Prayfile`.

[Trunk](https://docs.trunk.io) config lives in `.trunk/`; CI can run `trunk` via `.github/workflows/_trunk_check.yml`. Releases: `make release` or `usr/bin/release.rb`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Bug reports and pull requests are welcome at https://github.com/amkisko/activeadmin_batched_export.rb/issues

## License

MIT — see [LICENSE.md](LICENSE.md).

## Sponsors

Sponsored by [Kisko Labs](https://www.kiskolabs.com).

<a href="https://www.kiskolabs.com">
  <img src="kisko.svg" width="200" alt="Sponsored by Kisko Labs" />
</a>
