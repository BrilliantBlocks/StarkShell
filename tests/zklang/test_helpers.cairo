%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin

from src.zklang.ZKlang import Instruction, _get_row_from_matrix_by_index, _get_row_from_matrix_by_key, VariableType

from protostar.asserts import assert_eq


// TODO tempvar x = new (1,1,1,1,1);

@external
func test_get_row_from_matrix_by_index{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    let (local ptr: felt*) = alloc();
    assert ptr[0] = 3;
    assert ptr[1] = 11;
    assert ptr[2] = 12;
    assert ptr[3] = 13;
    assert ptr[4] = 2;
    assert ptr[5] = 21;
    assert ptr[6] = 22;
    let (instruction_len, instruction) = _get_row_from_matrix_by_index(0, 7, ptr);
    assert_eq(instruction_len, 3);
    assert_eq(instruction[0], 11);
    assert_eq(instruction[1], 12);
    assert_eq(instruction[2], 13);
    let (instruction_len, instruction) = _get_row_from_matrix_by_index(1, 7, ptr);
    assert_eq(instruction_len, 2);
    assert_eq(instruction[0], 21);
    assert_eq(instruction[1], 22);
    return ();
}

/// @dev ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
/// @dev || selector || protected || type || len || x0 || x1 || ... || x_(len-1) ||
/// @dev ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
@external
func test_get_row_from_matrix_by_key_on_single_element_in_memory{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    let (local ptr: felt*) = alloc();
    assert ptr[0] = 123456;
    assert ptr[1] = FALSE;
    assert ptr[2] = VariableType.FELT;
    assert ptr[3] = 3;
    assert ptr[4] = 3;
    assert ptr[5] = 2;
    assert ptr[6] = 1;
    let (var_data_len, var_data, flag) = _get_row_from_matrix_by_key(123456, 7, ptr);
    assert_eq(var_data_len, 3);
    assert_eq(var_data[0], 3);
    assert_eq(var_data[1], 2);
    assert_eq(var_data[2], 1);
    return ();
}

@external
func test_get_row_from_matrix_by_key_on_multiple_elements_in_memory{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    let (local ptr: felt*) = alloc();
    assert ptr[0] = 123456;
    assert ptr[1] = FALSE;
    assert ptr[2] = VariableType.FELT;
    assert ptr[3] = 3;
    assert ptr[4] = 0;
    assert ptr[5] = 0;
    assert ptr[6] = 0;
    assert ptr[7] = 987654;
    assert ptr[8] = FALSE;
    assert ptr[9] = VariableType.FELT;
    assert ptr[10] = 3;
    assert ptr[11] = 0;
    assert ptr[12] = 0;
    assert ptr[13] = 0;
    assert ptr[14] = 345678;
    assert ptr[15] = FALSE;
    assert ptr[16] = VariableType.FELT;
    assert ptr[17] = 7;
    assert ptr[18] = 0;
    assert ptr[19] = 0;
    assert ptr[20] = 0;
    assert ptr[21] = 0;
    assert ptr[22] = 0;
    assert ptr[23] = 0;
    assert ptr[24] = 7;

    let (var_data_len, var_data, flag) = _get_row_from_matrix_by_key(123456, 24, ptr);
    assert_eq(var_data_len, 3);
    assert_eq(var_data[0], 0);
    assert_eq(var_data[1], 0);
    assert_eq(var_data[2], 0);

    let (var_data_len, var_data, flag) = _get_row_from_matrix_by_key(987654, 24, ptr);
    assert_eq(var_data_len, 3);
    assert_eq(var_data[0], 0);
    assert_eq(var_data[1], 0);
    assert_eq(var_data[2], 0);

    let (var_data_len, var_data, flag) = _get_row_from_matrix_by_key(345678, 24, ptr);
    assert_eq(var_data_len, 7);
    assert_eq(var_data[0], 0);
    assert_eq(var_data[1], 0);
    assert_eq(var_data[2], 0);
    assert_eq(var_data[3], 0);
    assert_eq(var_data[4], 0);
    assert_eq(var_data[5], 0);
    assert_eq(var_data[6], 7);

    return ();
}

@external
func test_get_row_from_matrix_by_key_returns_zeros_if_selector_not_found{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    let (local ptr: felt*) = alloc();
    assert ptr[0] = 123456;
    assert ptr[1] = FALSE;
    assert ptr[2] = VariableType.FELT;
    assert ptr[3] = 3;
    assert ptr[4] = 0;
    assert ptr[5] = 0;
    assert ptr[6] = 0;
    assert ptr[7] = 987654;
    assert ptr[8] = FALSE;
    assert ptr[9] = VariableType.FELT;
    assert ptr[10] = 3;
    assert ptr[11] = 0;
    assert ptr[12] = 0;
    assert ptr[13] = 0;
    assert ptr[14] = 345678;
    assert ptr[15] = FALSE;
    assert ptr[16] = VariableType.FELT;
    assert ptr[17] = 7;
    assert ptr[18] = 0;
    assert ptr[19] = 0;
    assert ptr[20] = 0;
    assert ptr[21] = 0;
    assert ptr[22] = 0;
    assert ptr[23] = 0;
    assert ptr[24] = 7;

    let (var_data_len, var_data, flag) = _get_row_from_matrix_by_key(191919, 24, ptr);
    assert_eq(var_data_len, 0);
    assert_eq(flag.selector, 0);
    assert_eq(flag.protected, 0);
    assert_eq(flag.type, 0);

    return ();
}

@external
func test_get_row_from_matrix_by_key_returns_zeros_if_memory_is_empty{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    let (local ptr: felt*) = alloc();

    let (var_data_len, var_data, flag) = _get_row_from_matrix_by_key(123456, 0, ptr);
    assert_eq(var_data_len, 0);
    assert_eq(flag.selector, 0);
    assert_eq(flag.protected, 0);
    assert_eq(flag.type, 0);

    return ();
}
