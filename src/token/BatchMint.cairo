%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_eq, uint256_check
from starkware.cairo.common.registers import get_label_location

from src.token.ERC721.util.Safemath import SafeUint256
from src.constants import FUNCTION_SELECTORS


@storage_var
func _owners(token_id: Uint256) -> (res: felt) {
}

@storage_var
func _balances(owner: felt) -> (res: Uint256) {
}


@event
func ConsecutiveTransfer(from_token_id: Uint256, to_token_id: Uint256, to_address: felt) {
}


@external
func mintBatchConsecutive{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_token_id: Uint256, to_token_id: Uint256, to_address: felt
) -> () {

    with_attr error_message("Receiver address must not be zero") {
        assert_not_zero(to_address);
    }

    let (valid_range) = uint256_le(from_token_id, to_token_id);
    with_attr error_message("First tokenId must be lower than second tokenId") {
        assert valid_range = TRUE;
    }

    mint_batch_consecutive(from_token_id, to_token_id, to_address);
    
    ConsecutiveTransfer.emit(from_token_id, to_token_id, to_address);
    return ();
}


func mint_batch_consecutive{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    current_token_id: Uint256, to_token_id: Uint256, to_address: felt
) -> () {

    let (is_equal) = uint256_eq(current_token_id, to_token_id);
    if (is_equal == TRUE) {
        return ();
    }

    _mint(to_address, current_token_id);

    let (next_token_id) = SafeUint256.add(current_token_id, Uint256(1, 0));

    mint_batch_consecutive(next_token_id, to_token_id, to_address);
    return ();
}


func _mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, token_id: Uint256
) -> () {
    with_attr error_message("Token ID is not valid") {
        uint256_check(token_id);
    }

    let (exists) = _exists(token_id);
    with_attr error_message("Token already minted") {
        assert exists = FALSE;
    }

    let (balance) = _balances.read(to);
    let (new_balance) = SafeUint256.add(balance, Uint256(1, 0));
    _balances.write(to, new_balance);
    _owners.write(token_id, to);

    return ();
}


func _exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (res: felt) {
    let (res) = _owners.read(token_id);

    if (res == 0) {
        return (FALSE,);
    } else {
        return (TRUE,);
    }
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
    dw FUNCTION_SELECTORS.BATCHMINT.mintBatchConsecutive;
}


// @dev Support ERC-165
// @param interface_id
// @return success (0 or 1)
@view
func __supports_interface__(_interface_id: felt) -> (success: felt) {

    return (FALSE,);
}