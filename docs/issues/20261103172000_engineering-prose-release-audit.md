# Engineering, prose, and release audit

## Participants

Andrei Makarov (@amkisko)

## Decisions

- Keep version 0.3.3. Fold audit fixes into the unpublished cut and date the product changelog 2026-11-03.
- Enforce max_export_rows on every live batch when export_snapshot is blank; a client export_cursor does not skip the cap.
- Keep release confirmation EOF as rejection, require a CHANGELOG version heading, and run tests on pull requests.
- Document freeze mode as integer primary keys only (bigint record_id).
- Leave UUID freeze support, full-id freeze pluck streaming, Stimulus controller fetch tests, and snapshot token user binding as follow-up work.

## Effects

Pipeline: workspace or batch HTTP -> authorize READ -> format ACL -> meta or live or freeze page -> ChunkRenderer -> Stimulus assembly. Boundary mode covered forged cursor bypass of the row cap. Queue, worker, learned-system, and physical plant modes skipped (absent).

Ranked fixes applied:

1. Live batch max_export_rows refuse with export_cursor present (high, observed).
2. Release changelog heading specs and EOF confirmation coverage (medium, observed).
3. Workspace disabled-format example asserts unauthorized (low, futile coverage).
4. ASCII punctuation in README and workspace summary placeholder; integer-key freeze note in README.

## Next

- Commit the worktree, then run make release for tag and gem push.
- Follow-up: UUID or string freeze ids; stream freeze inserts; Stimulus controller node tests; bind snapshot tokens to the admin user.

## Source

docs/reviews/20261103172000_engineering-prose-release-audit.md
CHANGELOG.md section 0.3.3 (2026-11-03)
docs/reviews/20261028094500_engineering-audit.md
