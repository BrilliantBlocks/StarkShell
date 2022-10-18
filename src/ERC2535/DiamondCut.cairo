%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.registers import get_label_location

from src.constants import FUNCTION_SELECTORS, IDIAMONDCUT_ID
from src.ERC2535.IDiamondCut import DiamondCut
from src.ERC2535.library import Diamond


/// @emit DiamondCut
/// @revert UNAUTHORIZED if not owner of diamond
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
@external
func setAlias{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _alias: felt, _alias_selector: felt, _assigned_selector: felt
) {
    Diamond.Assert.only_owner();
    Diamond._setAlias(_alias, _alias_selector, _assigned_selector);
    return ();
}

/// @revert UNKNOWN FUNCTION
@external
func setFunctionFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _chargee: felt, _charger: felt, _amount: felt, _erc20_contract: felt
) {
    Diamond.Assert.only_owner();
    Diamond._setFunctionFee(_chargee, _charger, _amount, _erc20_contract);
    return ();
}

@external
func __init_facet__() -> () {
    return ();
}

@view
func __get_function_selectors__() -> (res_len: felt, res: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (res_len=3, res=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.DIAMONDCUT.diamondCut;
    dw FUNCTION_SELECTORS.DIAMONDCUT.setAlias;
    dw FUNCTION_SELECTORS.DIAMONDCUT.setFunctionFee;
}

/// @dev ERC-165
@view
func __supports_interface__(_interface_id: felt) -> (success: felt) {
    if (_interface_id == IDIAMONDCUT_ID) {
        return (TRUE,);
    }
    return (FALSE,);
}
