%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.registers import get_label_location

from src.token.erc5114.library import ERC5114, NFT
from src.constants import FUNCTION_SELECTORS, IERC5114_ID



@view
func ownerOf{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    token_id: Uint256
) -> (nft: NFT) {

    return ERC5114.owner_of(token_id);
}


@view
func metadataFormat{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    metadata_format: felt
) {

    return ERC5114.metadata_format();
}


@external
func __init_facet__{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    metadata_format: felt
) -> () {
    
    ERC5114.initializer(metadata_format);
    return ();
}


@view
func __get_function_selectors__() -> (res_len: felt, res: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (res_len=2, res=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.ERC5114.ownerOf;
    dw FUNCTION_SELECTORS.ERC5114.metadataFormat;
}


// @dev Support ERC-165
// @param interface_id
// @return success (0 or 1)
@view
func __supports_interface__(_interface_id: felt) -> (success: felt) {
    if (_interface_id == IERC5114_ID) {
        return (TRUE,);
    }

    return (FALSE,);
}