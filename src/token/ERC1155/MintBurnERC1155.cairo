%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256 

from src.token.ERC1155.library import ERC1155


@external
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, token_id: Uint256, amount: Uint256
) -> () {

    return ERC1155._mint(to, token_id, amount);
}


@external
func mint_batch{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokens_id_len: felt, tokens_id: Uint256*, amounts_len: felt, amounts: Uint256*
) -> () {

    return ERC1155._mint_batch(to, tokens_id_len, tokens_id, amounts_len, amounts);
}


@external
func burn{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, token_id: Uint256, amount: Uint256
) {

    return ERC1155._burn(from_, token_id, amount);
}


@external
func burn_batch{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, tokens_id_len: felt, tokens_id: Uint256*, amounts_len: felt, amounts: Uint256*
) {
    
    return ERC1155._burn_batch(from_, tokens_id_len, tokens_id, amounts_len, amounts);
}