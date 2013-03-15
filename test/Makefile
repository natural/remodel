mocha := ../node_modules/mocha/bin/mocha --compilers coffee:coffee-script --timeout 5000 --slow 3000 --reporter spec

.PHONY: all

all:
	@$(mocha) .

%:
	@$(mocha) $@.coffee
