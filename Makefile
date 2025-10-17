SHELL := /bin/bash

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
