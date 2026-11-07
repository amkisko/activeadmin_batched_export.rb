# Engineering and prose audit before 0.3.3 publish

## Participants

Andrei Makarov (@amkisko)

## Decisions

Re-audit main for the unpublished 0.3.3 cut. Include live-batch max_export_rows admission, release confirmation and changelog gates, pull_request CI, workspace format ACL assertion, and ASCII docs punctuation. Leave tag and RubyGems publish to make release after commit.

## Effects

Pipeline: HTTP export -> ControllerMethods -> authz and format ACL -> keyset or snapshot page -> ChunkRenderer -> Stimulus Blob. Boundary mode covered forged export_cursor against the row cap. Resource and identification modes: export bodies may hold personal data; no new gem log fields. Queue, worker, learned-system, and physical plant modes skipped (absent).

Ranked fixes applied:

1. Refuse max_export_rows on live batches even when export_cursor is set (high confidence, observed).
2. Changelog heading and confirmation specs; CHANGELOG dated 2026-11-03.
3. Workspace disabled-format request expects unauthorized.
4. ASCII and integer-key freeze note on README; ASCII placeholder in summary partial.

Deferred (documented in the issue): UUID freeze / to_i, full-id freeze pluck memory, Stimulus controller tests, snapshot token user binding.

Checks observed in this session:

- bundle exec rubocop: 66 files, no offenses.
- bundle exec rbs validate: ok.
- polyrun javascript shards: 5 tests, 0 failures.
- polyrun parallel-rspec: 5 workers, exit 0 (includes release_confirmation and cap cursor refuse).
- gem build activeadmin_batched_export.gemspec and Gem::Package#verify for 0.3.3: ok (26624 bytes).

## Next

Commit, then make release.

## Source

- docs/issues/20261103172000_engineering-prose-release-audit.md
- CHANGELOG.md section 0.3.3 (2026-11-03)
