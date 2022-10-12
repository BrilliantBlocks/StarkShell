%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.uint256 import Uint256 
from starkware.cairo.common.registers import get_label_location

from src.token.ERC1155.library import ERC1155
from src.constants import FUNCTION_SELECTORS


@external
func mintBatch{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokens_id_len: felt, tokens_id: Uint256*, amounts_len: felt, amounts: Uint256*
) -> () {

    return ERC1155._mint_batch(to, tokens_id_len, tokens_id, amounts_len, amounts);
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
    dw FUNCTION_SELECTORS.MintBurnERC1155.mintBatch;
}


// @dev Support ERC-165
// @param interface_id
// @return success (0 or 1)
@view
func __supports_interface__(_interface_id: felt) -> (success: felt) {

    return (FALSE,);
}