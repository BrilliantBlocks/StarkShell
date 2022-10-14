%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.uint256 import Uint256 
from starkware.cairo.common.registers import get_label_location

from src.ERC1155.library import ERC1155
from src.constants import FUNCTION_SELECTORS, IERC1155_ID


@view
func balanceOf{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owner: felt, token_id: Uint256
) -> (balance: Uint256) {

    return ERC1155.balance_of(owner, token_id);
}


@view
func balanceOfBatch{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owners_len: felt, owners: felt*, tokens_id_len: felt, tokens_id: Uint256*
) -> (balances_len: felt, balances: Uint256*) {
    
    return ERC1155.balance_of_batch(owners_len, owners, tokens_id_len, tokens_id);
}


@view
func isApprovedForAll{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owner: felt, operator: felt
) -> (bool: felt) {

    return ERC1155.is_approved_for_all(owner, operator);
}


@external
func setApprovalForAll{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    operator: felt, approved: felt
) {

    return ERC1155.set_approval_for_all(operator, approved);
}


@external
func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, token_id: Uint256, amount: Uint256
) {
    
    return ERC1155.safe_transfer_from(from_, to, token_id, amount);
}


@external
func safeBatchTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokens_id_len: felt, tokens_id: Uint256*, amounts_len: felt, amounts: Uint256*
) {

    return ERC1155.safe_batch_transfer_from(from_, to, tokens_id_len, tokens_id, amounts_len, amounts);
}


@external
func __init_facet__{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> () {

    return ();
}


@view
func __get_function_selectors__() -> (res_len: felt, res: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (res_len=6, res=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.ERC1155.balanceOf;
    dw FUNCTION_SELECTORS.ERC1155.balanceOfBatch;
    dw FUNCTION_SELECTORS.ERC1155.isApprovedForAll;
    dw FUNCTION_SELECTORS.ERC1155.setApprovalForAll;
    dw FUNCTION_SELECTORS.ERC1155.safeTransferFrom;
    dw FUNCTION_SELECTORS.ERC1155.safeBatchTransferFrom;
}


// @dev Support ERC-165
// @param interface_id
// @return success (0 or 1)
@view
func __supports_interface__(_interface_id: felt) -> (success: felt) {
    if (_interface_id == IERC1155_ID) {
        return (TRUE,);
    }

    return (FALSE,);
}
