%lang starknet

/// @dev Enum
struct FacetCutAction {
    Add: felt,
    Remove: felt,
}

struct FacetCut {
    facetAddress: felt,
    facetCutAction: felt,
}


struct Fee {
    charger: felt,
    amount: felt,
    erc20_contract: felt,
}

/// @selector 0x3c27a8b448fe684611cd3c9b512daa99c6543934865e0e59b40602bd8db4ea8
@event
func DiamondCut(
    _address: felt, _facetCutAction: felt, _init: felt, _calldata_len: felt, _calldata: felt*
) {
}

/// @selector 0xf6c02362df0f19e3d15dda5d9a650cc9f369907e8c5d36f99c0fdbcb84e6d0
@event
func SetAlias(alias: felt, alias_selector: felt, assigned_selector: felt) {
}

/// @selector 0x230f7ba57083bd3af29b5549569aeb558350a7a4519a9b5f755eda20d1c5d80
@event
func SetFunctionFee(_chargee: felt, _charger: felt, _amount: felt, erc_contract: felt) {
}

@contract_interface
namespace IDiamondCut {
    /// @selector 0xf3d1ef016a3319b5c905f7ed8ae0708b96b732c565c6058e6a4f0291032848
    func diamondCut(
        // _address: felt, _facetCutAction: felt, _init: felt, _calldata_len: felt, _calldata: felt*
        _facetCut_len: felt, _facetCut: FacetCut*, _calldata_len: felt, _calldata: felt*
    ) -> () {
    }
}

@contract_interface
namespace ILanguage {
    func setAlias(_alias: felt, _alias_selector: felt, _assigned_selector: felt) -> () {
    }
}
