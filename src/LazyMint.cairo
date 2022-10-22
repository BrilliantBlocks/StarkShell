%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_equal, assert_not_zero
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.registers import get_label_location

//from src.token.ERC721.library import ERC721
from src.constants import FUNCTION_SELECTORS



@storage_var
func _whitelist(id: felt) -> (address: felt) {
}

@storage_var
func _whitelist_setting() -> (bool: felt) {
}


@external
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, token_id: Uint256
) -> () {
    
    let (whitelist_enabled) = _whitelist_setting.read();
    if (whitelist_enabled == TRUE) {
        return assert_whitelisted();
    }
    //return ERC721._mint(to, token_id);
    return ();
}


func assert_whitelisted{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> () {
    
    let (caller_address) = get_caller_address();

    let (is_whitelisted) = iterate_whitelist(caller_address, 0);

    with_attr error_message("You are not whitelisted for this mint") {
        assert is_whitelisted = TRUE;
    }

    return ();
}


func iterate_whitelist{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    minter_address: felt, current_id: felt
) -> (bool: felt) {
    
    let (whitelist_entry) = _whitelist.read(current_id);

    if (whitelist_entry == 0) {
        return (FALSE,);
    }

    if (whitelist_entry == minter_address) {
        return (TRUE,);
    }

    return iterate_whitelist(minter_address, current_id + 1);

}


@external
func addToWhitelist{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    minter_address_array_len: felt, minter_address_array: felt*
) -> () {
    with_attr error_message("Minter address array must not be empty") {
        assert_not_zero(minter_address_array_len);
    }

    add_to_whitelist(minter_address_array_len, minter_address_array);
    return ();
}


func add_to_whitelist{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    minter_address_array_len: felt, minter_address_array: felt*
) -> () {

    if (minter_address_array_len == 0) {
        return ();
    }
    
    let (next_free_id) = get_next_free_id(0);
    _whitelist.write(next_free_id, minter_address_array[0]);

    return add_to_whitelist(minter_address_array_len - 1, minter_address_array + 1);
}


func get_next_free_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    current_id: felt
) -> (next_free_id: felt) {
    
    let (whitelist_entry) = _whitelist.read(current_id);

    if (whitelist_entry == 0) {
        return (0,);
    }

    let (sum) = get_next_free_id(current_id + 1);
    return (sum + 1,);
}


@external
func changeWhitelistSetting{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    whitelist_setting: felt
) -> () {
    
    with_attr error_message("Whitelist setting parameter is not a boolean.") {
        assert whitelist_setting * (1 - whitelist_setting) = 0;
    }
    _whitelist_setting.write(whitelist_setting);
    return ();
}


@view
func getWhitelistSetting{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    whitelist_setting: felt
) {
    
    let (whitelist_setting) = _whitelist_setting.read();
    return (whitelist_setting,);
}


@external
func __init_facet__{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    whitelist_setting: felt
) -> () {
    
    with_attr error_message("Whitelist setting parameter is not a boolean.") {
        assert whitelist_setting * (1 - whitelist_setting) = 0;
    }
    _whitelist_setting.write(whitelist_setting);
    return ();
}


@view
func __get_function_selectors__() -> (res_len: felt, res: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (res_len=4, res=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.LAZYMINT.mint;
    dw FUNCTION_SELECTORS.LAZYMINT.addToWhitelist;
    dw FUNCTION_SELECTORS.LAZYMINT.changeWhitelistSetting;
    dw FUNCTION_SELECTORS.LAZYMINT.getWhitelistSetting;
}


// @dev Support ERC-165
// @param interface_id
// @return success (0 or 1)
@view
func __supports_interface__(_interface_id: felt) -> (success: felt) {

    return (FALSE,);
}
