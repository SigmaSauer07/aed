SHELL := /bin/bash

.PHONY: install compile test coverage deploy-amoy clean

install:
npm install

compile:
npx hardhat compile

test:
npx hardhat test

coverage:
npx hardhat coverage

deploy-amoy:
npx hardhat run scripts/deploy.js --network amoy

clean:
rm -rf cache artifacts coverage
