.PHONY: install compile test frontend-home frontend-admin clean

install:
npm install

compile:
npx hardhat compile

test:
npx hardhat test

frontend-home:
npx http-server frontend/aed-home -p 5173 -c-1

frontend-admin:
npx http-server frontend/aed-admin -p 5174 -c-1

clean:
rm -rf cache artifacts coverage node_modules
