%lang starknet

@contract_interface
namespace IDiamond {
    func facetAddresses() -> (res_len: felt, res: felt*) {
    }

    func facets() -> (res_len: felt, res: felt*) {
    }

    func facetFunctionSelectors(_facet: felt) -> (res_len: felt, res: felt*) {
    }

    func facetAddress(_functionSelector: felt) -> (res: felt) {
    }

    func getImplementation() -> (res: felt) {
    }
}
