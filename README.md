<p align="center"> 
  <img src="images/brilliantblocks_logo.png" alt="brilliantblocks-logo" width="30%" height="30%">
</p>
<h1 align="center"> StarkShell </h1>

This repository contains StarkShell, an on-chain virtual machine (VM), and its surrounding code base for a modular smart contract system.
It can be used for both on-chain development as well as exploratory testing.

## Features

- [x] Dynamic interface
- [x] Ad hoc interpreter
- [x] Access NFTs
- [x] Parameterizable functions
- [x] Import system
- [x] On-chain deployment
- [ ] Storage system

## Repository Overview

The diamond contract:
- [src/components/diamond](./src/components/diamond/)

Functional extensions for diamonds aka. *the facets*:
- [src/components/facets](./src/components/facets/)

    Configurability and upgradability:
    - [src/components/facets/upgradability](./src/components/facets/upgradability)

    StarkShell facet:
    - [src/components/facets/starkshell](./src/components/facets/starkshell)

Bootstrapper contract:
- [src/bootstrap](./src/bootstrap)

## How To Get Started

1. Start your local development server
```bash
starknet-devnet
```

2. Make `starkshell.sh` executable and run the script for initializing the dApp.
```bash
chmod +x starkshell.sh
./starkshell.sh
```

The script deploys a root diamond, which itself is a VM.
The functionality which is not covered by other components is programmed with StarkShell.
The encoded instructions are in [src/starkshell](./src/starkshell).
