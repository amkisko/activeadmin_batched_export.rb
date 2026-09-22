# Reject mismatched data formats

## Decisions

After export_meta JSON and matching-format batch handling, csv, json, and xml requests return 406 instead of rendering the HTML workspace.

## Effects

json format with csv export_format and no export_meta is 406. Matching batch and json export_meta stay 200.

## Next

Shipped in 0.3.1. make release when ready to tag and push the gem.

## Source

usr/docs/issues/20260907141800_mismatched-export-format-406.md. lib/activeadmin/batched_export/controller_methods.rb.
