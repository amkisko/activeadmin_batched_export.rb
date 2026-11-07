# Release confirmation

## Participants

Andrei Makarov (@amkisko)

## Decisions

- Cut patch 0.3.3 for the release operator workflow and the live-batch row-cap admit path.
- Reject end of input at the confirmation prompt while accepting an entered empty line or yes.
- Require a CHANGELOG.md version heading before gem push.
- Start quality, test, and coverage jobs for pull requests; give the test workflow read-only contents permission.
- Refuse max_export_rows on every live batch (no snapshot token), including requests that send export_cursor.

## Effects

- The confirmation spec failed before the helper was added and passed afterward.
- Changelog heading specs cover accept, Unreleased reject, and require_changelog_version! abort or pass.
- Cap request spec refuses an over-cap live batch that carries a forged export_cursor.
- Updated CHANGELOG.md, the version constant, and path-gem lockfile entries.

## Next

- Review the changes and publish only after the normal clean-tree release gate passes.

## Source

- usr/bin/release.rb
- usr/lib/release_version_check.rb
- spec/release_confirmation_spec.rb
- spec/requests/batched_export_cap_spec.rb
- lib/activeadmin/batched_export/controller_methods.rb
