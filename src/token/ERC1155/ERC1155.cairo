%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256 

from src.token.ERC1155.library import ERC1155


@view
func balanceOf{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owner: felt, token_id: Uint256
) -> (balance: Uint256) {

    return ERC1155.balanceOf(owner, token_id);
}


@view
func balanceOfBatch{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owners_len: felt, owners: felt*, tokens_id_len: felt, tokens_id: Uint256*
) -> (balances_len: felt, balances: Uint256*) {
    
    return ERC1155.balanceOfBatch(owners_len, owners, tokens_id_len, tokens_id);
}


@view
func isApprovedForAll{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owner: felt, operator: felt
) -> (bool: felt) {

    return ERC1155.isApprovedForAll(owner, operator);
}


@external
func setApprovalForAll{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    operator: felt, approved: felt
) {

    return ERC1155.setApprovalForAll(operator, approved);
}


@external
func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, token_id: Uint256, amount: Uint256
) {
    
    return ERC1155.safeTransferFrom(from_, to, token_id, amount);
}


@external
func safeBatchTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokens_id_len: felt, tokens_id: Uint256*, amounts_len: felt, amounts: Uint256*
) {

    return ERC1155.safeBatchTransferFrom(from_, to, tokens_id_len, tokens_id, amounts_len, amounts);
}


@external
func _mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, token_id: Uint256, amount: Uint256
) -> () {

    return ERC1155._mint(to, token_id, amount);
}


@external
func _mint_batch{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokens_id_len: felt, tokens_id: Uint256*, amounts_len: felt, amounts: Uint256*
) -> () {

    return ERC1155._mint_batch(to, tokens_id_len, tokens_id, amounts_len, amounts);
}


@external
func _burn{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, token_id: Uint256, amount: Uint256
) {

    return ERC1155._burn(from_, token_id, amount);
}


@external
func _burn_batch{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, tokens_id_len: felt, tokens_id: Uint256*, amounts_len: felt, amounts: Uint256*
) {
    
    return ERC1155._burn_batch(from_, tokens_id_len, tokens_id, amounts_len, amounts);
}
