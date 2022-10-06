%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.uint256 import Uint256, uint256_check
from starkware.cairo.common.math import assert_not_zero, assert_le
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.registers import get_label_location
from starkware.starknet.common.syscalls import get_block_timestamp

from src.constants import FUNCTION_SELECTORS


struct UserInfo {
    address: felt,
    expires: felt,
}


@event
func UpdateUser(token_id: Uint256, user: UserInfo) {
}


@storage_var
func _users(token_id: Uint256) -> (user: UserInfo) {
}


@external
func setUser{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    token_id: Uint256, user: UserInfo
) -> () {

    with_attr error_message("Token is not a valid Uint256") {
        uint256_check(token_id);
    }
    
    _users.write(token_id, user);
    UpdateUser.emit(token_id, user);
    return ();
}


@view
func userOf{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    token_id: Uint256
) -> (user_address: felt) {

    with_attr error_message("Token is not a valid Uint256") {
        uint256_check(token_id);
    }

    let (user) = _users.read(token_id);
    let (block_timestamp) = get_block_timestamp();

    if (is_le(block_timestamp, user.expires) == TRUE) {
        return (user.address,);
    }

    return (0,);
}


@view
func userExpires{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    token_id: Uint256
) -> (expires: felt) {

    with_attr error_message("Token is not a valid Uint256") {
        uint256_check(token_id);
    }
    let (user) = _users.read(token_id);

    return (user.expires,);
}



