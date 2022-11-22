%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.uint256 import Uint256, uint256_check
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.registers import get_label_location
from starkware.starknet.common.syscalls import get_block_timestamp

from src.zkode.constants import FUNCTION_SELECTORS, IERC4907_ID

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
func userOf{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(token_id: Uint256) -> (
    user_address: felt
) {
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
func userExpires{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    token_id: Uint256
) -> (expires: felt) {
    with_attr error_message("Token is not a valid Uint256") {
        uint256_check(token_id);
    }
    let (user) = _users.read(token_id);

    return (user.expires,);
}

func beforeTokenTransfer{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, token_id: Uint256
) -> () {
    let (user) = _users.read(token_id);
    if (from_ != to) {
        if (user.address != 0) {
            _users.write(token_id, UserInfo(0, 0));
            UpdateUser.emit(token_id, UserInfo(0, 0));
            return ();
        }
    }

    return ();
}

@external
func __init_facet__{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> () {
    return ();
}

@view
func __pub_func__() -> (res_len: felt, res: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (res_len=3, res=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.ERC4907.setUser;
    dw FUNCTION_SELECTORS.ERC4907.userOf;
    dw FUNCTION_SELECTORS.ERC4907.userExpires;
}

// @dev Support ERC-165
// @param interface_id
// @return success (0 or 1)
@view
func __supports_interface__(_interface_id: felt) -> (success: felt) {
    if (_interface_id == IERC4907_ID) {
        return (TRUE,);
    }

    return (FALSE,);
}
