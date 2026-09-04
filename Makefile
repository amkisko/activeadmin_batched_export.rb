.PHONY: release lint test clean

release:
	ruby usr/bin/release.rb

lint:
	bundle exec rubocop
	bundle exec rbs validate

test: lint
	node --test spec/javascript/chunk_assembly.test.mjs
	bundle exec polyrun parallel-rspec --workers 5 --merge-failures

clean:
	rm -rf coverage .pray/cache tmp
	rm -f spec/examples.txt *.gem
