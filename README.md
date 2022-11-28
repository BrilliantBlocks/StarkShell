<p align="center"> 
  <img src="images/brilliantblocks_logo.png" alt="brilliantblocks-logo" width="30%" height="30%">
</p>
<h1 align="center"> ZKODE </h1>

[![Tests](https://github.com/BrilliantBlocks/diamond_v2/actions/workflows/main.yaml/badge.svg)](https://github.com/BrilliantBlocks/diamond_v2/actions/workflows/main.yaml)

This repository contains the code base for a modular smart contract system, which is built as a modified version of the “Diamond” ERC-2535 multi-facet proxy contract.
With this interface standard, smart contracts ("Diamonds") can be assembled from existing functionality components ("Facets") as individually required.
This enables composability and continuous upgradeability for developers.


## Features

- [x] Upgradability
- [x] On-chain deployment
- [x] Dynamic interface detection
- [x] ERC-20 - Fungible Tokens
- [x] ERC-721 - Non-Fungible Tokens
- [x] ERC-1155 - Semi-Fungible Tokens
- [x] ERC-5114 - Soulbound Badges
- [ ] ERC-2981 - Royalties
- [ ] ERC-4675 - Multi-Fractional NFTs


## Repository Overview

The main smart contract aka. *the diamond*:
- [src/diamond](./src/zkode/diamond/)

Functional extensions for diamonds aka. *the facets*:
- [src/facets](./src/zkode/facets/)

    Configurability and upgradability:
    - [src/facets/upgradability](./src/zkode/facets/upgradability)

    Catalog of supported token standards:
    - [src/facets/token](./src/zkode/facets/token)

        ERC-1155:
        - [src/facets/token/erc1155](./src/zkode/facets/token/erc1155)

        ERC-20:
        - [src/facets/token/erc20](./src/zkode/facets/token/erc20)

        ERC-5114:
        - [src/facets/token/erc5114](./src/zkode/facets/token/erc5114)

        ERC-721:
        - [src/facets/token/erc721](./src/zkode/facets/token/erc721)
    
    Single metadata facet for all token standards:
    - [src/facets/metadata](./src/zkode/facets/metadata)
