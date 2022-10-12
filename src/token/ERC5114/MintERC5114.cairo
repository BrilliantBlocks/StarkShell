%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.registers import get_label_location

from src.token.erc5114.library import ERC5114, NFT
from src.constants import FUNCTION_SELECTORS



@external
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    token_id: Uint256, nft: NFT
) -> () {
    
    return ERC5114._mint(token_id, nft);
}


@external
func __init_facet__{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> () {
    
    return ();
}


@view
func __get_function_selectors__() -> (res_len: felt, res: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (res_len=1, res=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.MintERC5114.mint;
}


// @dev Support ERC-165
// @param interface_id
// @return success (0 or 1)
@view
func __supports_interface__(_interface_id: felt) -> (success: felt) {

    return (FALSE,);
}