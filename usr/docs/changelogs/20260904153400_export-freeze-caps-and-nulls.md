# Export freeze, caps, and NULL sort keys

## Decisions

When the freeze table exists, the first batch stores filtered primary keys in NULL-safe order and later batches walk that list by position (RFC-0003). The token is not an access grant. Meta GET does not freeze.

max_export_rows default nil means unlimited. A COUNT larger than the cap is 400 on the first batch. Meta still returns 200 with over_max true.

NULL sort keys sort last in both directions without PostgreSQL NULLS LAST.

## Effects

Dummy schema gained priority, owned_notes, and active_admin_batched_export_snapshot_rows. Request specs cover freeze omit-after-insert, expired session 400, cap, NULL order, and scoped collection. node --test covers chunk assembly helpers extracted from the Stimulus controller.

## Next

Hash pepper, rate-limit product, and audit logging stay out of this pass.

## Source

RFC-0003. usr/docs/issues/20260904144900_engineering-audit.md.
