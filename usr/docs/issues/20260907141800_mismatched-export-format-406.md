# Mismatched export format 500

## Decisions

A csv, json, or xml batched_export request that is not JSON export_meta and not a matching-format batch is 406. Do not render the HTML workspace under those formats.

0.2.0 returned 406 when batch_page was set and request.format did not match export_format. 0.3.0 dropped batch_page and the 406 branch. Matching format plus missing export_meta is a batch walk. A mismatch fell through to render_export_workspace.

## Effects

Before the guard, POLYRUN_COVERAGE_DISABLE=1 bundle exec rspec spec/requests/batched_export_spec.rb:40 raised ActionView::MissingTemplate for workspace with formats json. After the guard, that example is 406. POLYRUN_COVERAGE_DISABLE=1 bundle exec rspec spec/requests/batched_export_spec.rb: 18 examples, 0 failures. make test: rubocop 63 files no offenses, rbs validate, 5 javascript tests pass, parallel-rspec 17 paths exit 0.

Stimulus batch URLs keep format and export_format aligned, so the happy path is unchanged.

## Next

Ship the guard in the gem. Hosts that prepend a mismatch 406 can drop that prepend after upgrade.

## Source

lib/activeadmin/batched_export/controller_methods.rb. spec/requests/batched_export_spec.rb. rfcs/0002-keyset-export-cursor.md. git tag 0.2.0 controller_methods.rb head :not_acceptable under batch_page.
