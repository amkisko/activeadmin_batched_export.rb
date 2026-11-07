# Engineering audit and release check

## Participants

Andrei Makarov (@amkisko)

## Decisions

- Review export authorization, keyset and snapshot paths, browser assembly, release flow, tests, CI, package contents, resource use, and identifying traces.
- Use the local Rails test application and Ruby 4.0.2 bundle. Do not treat the dummy application's records as a production-size export fixture.

## Effects

- Release confirmation: medium severity, high confidence, observed at usr/bin/release.rb. End of input previously passed the publish prompt. The focused spec failed before the fix and passed afterward.
- CI trigger: medium severity, high confidence, observed at .github/workflows/test.yml. Pull requests did not start the test workflow. The workflow now includes pull_request and has read-only contents permission; YAML parsing confirms both keys.
- make test, including JavaScript tests, bundle check, git diff --check, gem build, and Gem::Package#verify passed. The built 0.3.3 gem has 38 files and is 26624 bytes.
- Cold require in a Rails and ActiveAdmin host fixture used 0.531 user CPU seconds, 0.396 system CPU seconds, and 84639744 bytes peak RSS on this machine. Standalone require without Rails boot fails because the engine expects Rails to be loaded. Package build used 0.093 user CPU seconds, 0.046 system CPU seconds, and 30425088 bytes peak RSS. These are one-run measurements without a production export-size ceiling.
- Export query filters and CSV/JSON/XML bodies may contain personal data. The gem has no independent network client; browser transfer bytes and deployed logs were not captured. A large export fixture would establish peak memory, query counts, and network size. Browser visual and keyboard states need a running host surface.
- The optional snapshot table documented in README.md uses a bigint record_id. The current snapshot path converts identifiers to integers, so the documented freeze mode is limited to integer primary keys. UUID host behavior and migration of an existing host table were not validated in this patch release.
- The second source and test pass found no further confirmed, fixable findings within the documented integer-key snapshot contract.

## Next

- Run the full CI matrix and a production-shaped export fixture before publishing. Plan UUID snapshot support separately if a host needs it.

## Source

- lib/activeadmin/batched_export/controller_methods.rb
- lib/activeadmin/batched_export/snapshot_page.rb
- README.md
- usr/bin/release.rb
- .github/workflows/test.yml
- spec/requests/batched_export_snapshot_spec.rb
- spec/release_confirmation_spec.rb
