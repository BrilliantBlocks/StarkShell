# BrilliantBlocks

This is an adjusted ERC2535 implementation.
Facet class hash are stored in a registry.
Diamond has a single storage variable for its configuration.


## Features

- [x] Dynamic `supportsInterface`
- [x] Add all functions of class and not single functions
- [x] Aspect support
- [x] On-chain deployment (ownership of diamond is mapped to ERC-721 token)


## How To Develop Facets

Facets require three functions:

- `__init_facet__`
- `__get_function_selectors__`
- `__supports_interface__`


## Style Guide

- All special functions are prefix with a double underscore and kept in double underscored cairo file
- Capitalized cairo files are compiled and declared
- src/main contains components which are not based on the diamond
- external and view functions identifiers are camel cased
- all other functions are snake cased


## TODO

- [ ] NatSpec comments
- [ ] Enforce consistency
- [ ] CI
- [ ] CONTRIBUTE.md
- [ ] Test suite
- [x] Remove redundant facets
- [ ] Add zklang interfaces
- [ ] Purify and test code
- [ ] Collect interfaces and constants at a single entrypoint
- [ ] Remove BFR and TCF components
