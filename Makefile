NODE_BIN := npx

.PHONY: install compile test coverage lint clean

install:
	npm install

compile:
	$(NODE_BIN) hardhat compile

test:
	$(NODE_BIN) hardhat test

coverage:
	$(NODE_BIN) hardhat coverage

lint:
	$(NODE_BIN) prettier --check "**/*.{js,json,sol,md}"

clean:
	rm -rf artifacts cache coverage typechain
