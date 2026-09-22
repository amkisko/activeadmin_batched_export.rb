# JavaScript tests through Polyrun shards

## Decisions

JavaScript tests under spec/javascript are discovered by glob, written to a paths file, and fanned out with polyrun run-shards the same way RSpec uses spec/**/*_spec.rb.

polyrun.javascript.yml keeps that glob off the RSpec partition. make test, CI, and usr/bin/release.rb all run that command before parallel-rspec.

Matching names are *.{test,spec}.{mjs,js,cjs}. A single file still shards; empty extra workers skip.

## Effects

Makefile gained test-javascript. Node no longer takes one hardcoded path.

## Next

A later pass can add more assembly files under the same glob.

## Source

polyrun.javascript.yml. Makefile. .github/workflows/test.yml. usr/bin/release.rb.
