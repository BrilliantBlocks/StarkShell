%lang starknet
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin

from src.ERC2535.library import Diamond

// Facet-specifix external and view functions
from src.ERC2535.__DiamondCut import (
    __get_function_selectors__,
    __init_facet__,
    __supports_interface__,
)

/// @emit DiamondCut
/// @revert NOT AUTHORIZED if not owner of diamond
@external
func diamondCut{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(_address: felt, _facetCutAction: felt, _init: felt, _calldata_len: felt, _calldata: felt*) -> () {
    alloc_locals;
    Diamond.Assert.only_owner();
    Diamond._diamondCut(_address, _facetCutAction, _init, _calldata_len, _calldata);
    return ();
}

/// @emit SetAlias
/// @param _alias string representation of function
/// @revert UNKNOWN FUNCTION if _assigned_selector not in facets
/// @revert NOT AUTHORIZED if not owner of diamond
@external
func setAlias{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _alias: felt, _alias_selector: felt, _assigned_selector: felt
) {
    Diamond.Assert.only_owner();
    Diamond._setAlias(_alias, _alias_selector, _assigned_selector);
    return ();
}

/// @revert UNKNOWN FUNCTION
/// @revert NOT AUTHORIZED if not owner of diamond
@external
func setFunctionFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _chargee: felt, _charger: felt, _amount: felt, _erc20_contract: felt
) {
    Diamond.Assert.only_owner();
    Diamond._setFunctionFee(_chargee, _charger, _amount, _erc20_contract);
    return ();
}
