%lang starknet


@contract_interface
namespace IDiamondLoupe:
    func facetAddresses() -> (res_len: felt, res: felt*):
    end

    func facets() -> (res_len: felt, res: felt*):
    end

    func facetFunctionSelectors(_facet: felt) -> (res_len: felt, res: felt*):
    end

    func facetAddress(_functionSelector: felt) -> (res: felt):
    end
end
