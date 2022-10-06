%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.uint256 import Uint256, uint256_check
from starkware.cairo.common.math import assert_not_zero, assert_le, assert_in_range
from starkware.cairo.common.math_cmp import is_in_range
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.registers import get_label_location

from src.constants import FUNCTION_SELECTORS, IERC5007_ID



@storage_var
func _time_period(token_id: Uint256) -> (res: (start_time: felt, end_time: felt)) {
}



@view
func startTime{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (start_time: felt) {
    
    let (time_period) = _time_period.read(token_id);
	let start_time = time_period[0];

    return (start_time,);
}


@view
func endTime{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (end_time: felt) {
    
	let (time_period) = _time_period.read(token_id);
	let end_time = time_period[1];

    return (end_time,);
}


@external
func setTimePeriod{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256, start_time: felt, end_time: felt
) -> () {
    
	with_attr error_message("Token is not a valid Uint256") {
        uint256_check(token_id);
    }
    
    with_attr error_message("Start time must not be zero") {
        assert_not_zero(start_time);
    }

    with_attr error_message("End time must not be zero") {
        assert_not_zero(end_time);
    }

    with_attr error_message("End time must be higher than start time") {
        assert_le(start_time, end_time);
    }

    _time_period.write(token_id, (start_time, end_time));

    return ();
}


@view
func checkTimePeriod{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (bool: felt) {
    
	with_attr error_message("Token is not a valid Uint256") {
        uint256_check(token_id);
    }

    let (exists) = _exists(token_id);
    with_attr error_message("Time period for this token is not defined") {
        assert exists = TRUE;
    }

    let (block_timestamp) = get_block_timestamp();
    let (time_period) = _time_period.read(token_id);
    let start_time = time_period[0];
    let end_time = time_period[1];

    let in_range = is_in_range(block_timestamp, start_time, end_time);
    if (in_range == TRUE) {
        return (TRUE,);
    }

    return (FALSE,);
}


func assertTimePeriod{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> () {
    
	with_attr error_message("Token is not a valid Uint256") {
        uint256_check(token_id);
    }

    let (exists) = _exists(token_id);
    with_attr error_message("Time period for this token is not defined") {
        assert exists = TRUE;
    }

    let (block_timestamp) = get_block_timestamp();
    let (time_period) = _time_period.read(token_id);
    let start_time = time_period[0];
    let end_time = time_period[1];

    assert_in_range(block_timestamp, start_time, end_time);

    return ();
}


func _exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (bool: felt) {
    
    let (exists) = _time_period.read(token_id);
    
    if (exists[0] == FALSE) {
        return (FALSE,);
    }

    return (TRUE,);
}


@external
func __init_facet__{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> () {

    return ();
}


@view
func __get_function_selectors__() -> (res_len: felt, res: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (res_len=4, res=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.ERC5007.startTime;
    dw FUNCTION_SELECTORS.ERC5007.endTime;
    dw FUNCTION_SELECTORS.ERC5007.setTimePeriod;
    dw FUNCTION_SELECTORS.ERC5007.checkTimePeriod;
}


// @dev Support ERC-165
// @param interface_id
// @return success (0 or 1)
@view
func __supports_interface__(_interface_id: felt) -> (success: felt) {
    if (_interface_id == IERC5007_ID) {
        return (TRUE,);
    }

    return (FALSE,);
}