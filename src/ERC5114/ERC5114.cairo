%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.registers import get_label_location

from src.ERC5114.library import ERC5114, NFT
from src.constants import FUNCTION_SELECTORS, IERC5114_ID


@view
func ownerOf{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    token_id: Uint256
) -> (nft: NFT) {

    return ERC5114.owner_of(token_id);
}

// ===================
// Mandatory functions
// ===================

/// @dev Initialize this facet
@external
func __constructor__{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> () {
    return ();
}

/// @dev Remove this facet
@external
func __destructor__{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> () {
    return ();
}

/// @dev Exported view and invokable functions of this facet
@view
@raw_output
func __get_function_selectors__() -> (retdata_size: felt, retdata: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (retdata_size=1, retdata=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.ERC5114.ownerOf;
}

/// @dev Define all supported interfaces of this facet
@view
func __supports_interface__(_interface_id: felt) -> (res: felt) {
    if (_interface_id == IERC5114_ID) {
        return (res=TRUE);
    }
    return (res=FALSE);
}
