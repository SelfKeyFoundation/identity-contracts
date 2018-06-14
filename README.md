# did-claims

Smart contracts that implement self-sovereign identity, and verifiable claims.

* `develop` — [![CircleCI](https://circleci.com/gh/SelfKeyFoundation/id-claims/tree/develop.svg?style=svg)](https://circleci.com/gh/SelfKeyFoundation/id-claims/tree/develop)
* `master` — [![CircleCI](https://circleci.com/gh/SelfKeyFoundation/id-claims/tree/master.svg?style=svg)](https://circleci.com/gh/SelfKeyFoundation/id-claims/tree/master)

## Overview

Selfkey implementation of ERC725 identity standard. It adds functionality specific for acting as a
DID (Decentralized Identifier) contract, by providing the means to manage "service endpoints" and
also sending or withdrawing ETH/tokens.

## Development

The smart contracts are being implemented in Solidity `0.4.19`.

### Prerequisites

* [NodeJS](htps://nodejs.org), version 9.5+ (I use [`nvm`](https://github.com/creationix/nvm) to manage Node versions — `brew install nvm`.)
* [truffle](http://truffleframework.com/), which is a comprehensive framework for Ethereum development. `npm install -g truffle` — this should install Truffle v4+.  Check that with `truffle version`.
* [Access to the KYC_Chain Jira](https://kyc-chain.atlassian.net)

### Initialisation

    npm install

### Testing

#### Standalone

    npm test

or with code coverage

    npm run test:cov

#### From within Truffle

Run the `truffle` development environment

    truffle develop

then from the prompt you can run

    compile
    migrate
    test

as well as other Truffle commands. See [truffleframework.com](http://truffleframework.com) for more.

### Linting

We provide the following linting options

* `npm run lint:sol` — to lint the Solidity files, and
* `npm run lint:js` — to lint the Javascript.

## Contributing

Please see the [contributing notes](CONTRIBUTING.md).
