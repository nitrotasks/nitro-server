.PHONY: test blanket coveralls

MOCHA=./node_modules/.bin/mocha --compilers coffee:coffee-script/register
COVERALLS=./node_modules/.bin/coveralls

TESTS=test/*


test:
	  $(MOCHA) -R spec $(TESTS) --bail

blanket:
		@DISABLE_LOG=1 \
		$(MOCHA) -r blanket -R html-cov $(TESTS) > coverage.html

coveralls:
		@DISABLE_LOG=1 \
		$(MOCHA) -r blanket -R mocha-lcov-reporter $(TESTS) | $(COVERALLS)