# Sync appraisal locks after rbs 4 bump

## Participants
- amkisko
- Cursor agent

## Decisions
- Regenerate gemfiles/*.gemfile.lock after Dependabot raised the gemspec rbs floor from ~> 3 to ~> 4.
- Keep the gemspec constraint; do not pin appraisal graphs back to rbs 3.

## Effects
- CI test workflow failed on every matrix job and coverage: frozen bundle install rejected the Gemfile change while appraisal locks still declared rbs (~> 3).
- Appraisal locks now pin rbs 4.0.3 and rbs (~> 4), matching Gemfile.lock.

## Next
- Merge and confirm the test workflow is green on main.
- When Dependabot updates gemspec development deps that appraisal inherits, run bundle exec appraisal install before merge.

## Source
- Broken run: https://github.com/amkisko/activeadmin_batched_export.rb/actions/runs/29646462293
- Triggering merge: https://github.com/amkisko/activeadmin_batched_export.rb/commit/ff10f79180a152458a098fbb05682778a23f526b
