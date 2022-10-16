# Tokenized Contract Factory for ERC-2535 Diamonds


## Features

- Deploy contract by minting a ERC721 NFT
- Access and ownership is mapped to the NFT
- The NFT token id is equal to the token address
- Configure proxy


## How to convert between Uint256 token id and felt address?

```bash
python3 -c "print(hex(tokenId.low + 2**128 tokenId.high))"
```
