# Diamond v2

Latest deployment Info

```
❯ starknet declare --contract build/main.json --account brilliantblocks.v0.10.0
Sending the transaction with max\_fee: 0.000000 ETH.
Declare transaction was sent.
Contract class hash: 0x1c09d9c36446b116cc761711d73d9b2d7fd8b7e16d9fd63b3ee46cade7c3ca6
Transaction hash: 0x682b1ff182f5332b1588c718d3c4a149e53d247e26f01b965782ec754c90c30
```

```
~/dev/brilliantblocks/diamond-contracts-v2 poc !2 ?3 ────────────────────────────────────────────────── 20s Py diamond-contracts-v2
❯ starknet declare --contract build/ERC2535/DiamondCut.json --account brilliantblocks.v0.10.0
Sending the transaction with max\_fee: 0.000000 ETH.
Declare transaction was sent.
Contract class hash: 0x63c3ddc9077b89f5cc37a2b493ae194702dc29446c66ef000503052ef3af9fd
Transaction hash: 0x2575c3d1e1fbc7b45363611542c2e489a6bb734e4daedff9bc40b4f17a58653
```

```
~/dev/brilliantblocks/diamond-contracts-v2 poc !2 ?3 ────────────────────────────────────────────────── 13s Py diamond-contracts-v2
❯ starknet declare --contract build/token/ERC721/ERC721.json --account brilliantblocks.v0.10.0
Sending the transaction with max\_fee: 0.000000 ETH.
Declare transaction was sent.
Contract class hash: 0x5e41e636ad3921b36b89cca25c4cfa302e2febdc472c6a3665122fba43e7885
Transaction hash: 0x38d38074dc37c10803f68c96ed9cbf5c9a0bdcc4e765f3c01f444b2e68bd4f6
```

```
~/dev/brilliantblocks/diamond-contracts-v2 poc !2 ?3 ────────────────────────────────────────────────── 22s Py diamond-contracts-v2
❯ starknet declare --contract build/token/ERC721/mintdeploy.json --account brilliantblocks.v0.10.0
Sending the transaction with max\_fee: 0.000000 ETH.
Declare transaction was sent.
Contract class hash: 0x609c47df66a6e782f21ac75c1c7e0c1060f6ddd9b971956ab1a0c3a3b5de32c
Transaction hash: 0x4cbac6168b5538f9efe25c9241fb8a0fec941ce09ce1fa7e3edabd8de265f1e
```

```
❯ starknet deploy --class_hash 0x1c09d9c36446b116cc761711d73d9b2d7fd8b7e16d9fd63b3ee46cade7c3ca6 --account brilliantblocks.v0.10.0 --inputs 0 0x285ee4f49baf6a12a32403b7f64a95b7f4e473046d8e3d05b13fd0dc0df25fe 3 0x5e41e636ad3921b36b89cca25c4cfa302e2febdc472c6a3665122fba43e7885
Sending the transaction with max_fee: 0.000001 ETH.
Invoke transaction for contract deployment was sent.
Contract address: 0x04d1f7e91db9479aaeecc16a9edd961d352802fd95c8753c741e55ad2f0f8914
Transaction hash: 0x4ec9c0e17204fc92d60332d3de8f57c07ce91819f48573362fd1e27326e7ebf
```
