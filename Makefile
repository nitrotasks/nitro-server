.PHONY: test blanket coveralls

MOCHA=./node_modules/.bin/mocha --compilers coffee:coffee-script/register
COVERALLS=./node_modules/.bin/coveralls

TESTS=source/test/core/*


test:
		@BLUEBIRD_DEBUG=1 \
	  $(MOCHA) -R spec $(TESTS) --bail

watch:
	  $(MOCHA) -R spec $(TESTS) --bail --watch

blanket:
		@DISABLE_LOG=1 \
		$(MOCHA) -r blanket -R html-cov $(TESTS) | tee coverage.html

coveralls:
		@DISABLE_LOG=1 \
		$(MOCHA) -r blanket -R mocha-lcov-reporter $(TESTS) | $(COVERALLS)
