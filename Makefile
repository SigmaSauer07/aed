SHELL := /bin/bash
BUILD_DIR := build

.PHONY: install compile test coverage clean storage

install:
	npm install

compile: storage
	npx hardhat compile
	npx hardhat storage-layout > $(BUILD_DIR)/storage-layout.txt || true

storage:
	mkdir -p $(BUILD_DIR)

test:
	npx hardhat test

coverage:
	npx hardhat coverage

clean:
	rm -rf cache artifacts coverage $(BUILD_DIR)

.PHONY: install compile test coverage metadata clean

install:
npm install

compile:
npx hardhat compile

test:
npx hardhat test

coverage:
npx hardhat coverage

metadata:
node metadata-server/metadata-server.js

clean:
rm -rf cache artifacts coverage
