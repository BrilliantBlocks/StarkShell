%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.uint256 import Uint256, uint256_check, assert_uint256_le, uint256_add, uint256_sub
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.registers import get_label_location
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp

from src.constants import FUNCTION_SELECTORS


@event
func Transfer(from_: felt, to: felt, id: Uint256, value: Uint256) {
}

@event
func Approval(owner: felt, spender: felt, id: Uint256, value: Uint256) {
}

@event
func TokenAddition(parent_token: felt, parent_token_id: Uint256, id: Uint256, total_supply: Uint256) {
}


@storage_var
func _balances(owner: felt, id: Uint256) -> (res: Uint256) {
}




@external
func transfer{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, id: Uint256, value: Uint256
) -> (bool: felt) {
    
    with_attr error_message("Receiver must not be the zero address") {
        assert_not_zero(to);
    }
    
    let (caller) = get_caller_address();
    let (caller_balance) = _balances.read(caller, id);

    with_attr error_message("Token balance is unsufficient") {
        assert_uint256_le(value, caller_balance);
    }

    //Check if ID registered

    _transfer(caller, to, id, value);

    return (TRUE,);
}


@external
func transferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, id: Uint256, value: Uint256
) -> (bool: felt) {
    
    with_attr error_message("Receiver must not be the zero address") {
        assert_not_zero(to);
    }
    
    let (spender_balance) = _balances.read(from_, id);

    with_attr error_message("Token balance is unsufficient") {
        assert_uint256_le(value, spender_balance);
    }

    //Check if ID registered

    _transfer(from_, to, id, value);

    return (TRUE,);
}


func _transfer{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, id: Uint256, value: Uint256
) -> () {

    let (spender_balance) = _balances.read(from_, id);
    let (recipient_balance) = _balances.read(to, id);
    let (new_spender_balance) = uint256_sub(spender_balance, value);
    let (new_recipient_balance, _) = uint256_add(recipient_balance, value);

    _balances.write(from_, id, new_spender_balance);
    _balances.write(to, id, new_recipient_balance);

    return ();
}








