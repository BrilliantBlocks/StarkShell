%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.memcpy import memcpy

from src.constants import API
from src.zklang.library import DataTypes, Memory, Variable

from protostar.asserts import assert_eq


@external
func test_init_memory_on_empty_calldata{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    tempvar _calldata = new ();
    let _calldata_len = 0;

    tempvar var_metadata = new Variable(API.CORE.__ZKLANG__CALLDATA_VAR, FALSE, DataTypes.FELT, _calldata_len);
    let expected_memory = cast(var_metadata, felt*);
    let expected_memory_len = Variable.SIZE;

    let (actual_memory_len, actual_memory) = Memory.init(_calldata_len, _calldata);

    assert_eq(actual_memory_len, expected_memory_len);
    assert_eq(actual_memory[Variable.selector], expected_memory[Variable.selector]);
    assert_eq(actual_memory[Variable.protected], expected_memory[Variable.protected]);
    assert_eq(actual_memory[Variable.type], expected_memory[Variable.type]);
    assert_eq(actual_memory[Variable.data_len], expected_memory[Variable.data_len]);

    return ();
}

@external
func test_init_memory_on_non_single_width_calldata{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    tempvar _calldata = new (7);
    let _calldata_len = 1;

    tempvar var_metadata = new Variable(
        selector = API.CORE.__ZKLANG__CALLDATA_VAR,
        protected = FALSE,
        type = DataTypes.FELT,
        data_len = _calldata_len
    );
    let (local expected_memory: felt*) = alloc();
    let expected_memory_len = Variable.SIZE + _calldata_len;
    memcpy(expected_memory, cast(var_metadata, felt*), Variable.SIZE);
    memcpy(expected_memory + Variable.SIZE, _calldata, _calldata_len);

    let (actual_memory_len, actual_memory) = Memory.init(_calldata_len, _calldata);

    assert_eq(actual_memory_len, expected_memory_len);
    assert_eq(actual_memory[Variable.selector], expected_memory[Variable.selector]);
    assert_eq(actual_memory[Variable.protected], expected_memory[Variable.protected]);
    assert_eq(actual_memory[Variable.type], expected_memory[Variable.type]);
    assert_eq(actual_memory[Variable.data_len], expected_memory[Variable.data_len]);
    assert_eq(actual_memory[Variable.data_len + 1], expected_memory[Variable.data_len + 1]);

    return ();
}

@external
func test_init_memory_on_calldata_with_five_elements{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    tempvar _calldata = new (7, 0, -1, 9, 0);
    let _calldata_len = 5;

    tempvar var_metadata = new Variable(
        selector = API.CORE.__ZKLANG__CALLDATA_VAR,
        protected = FALSE,
        type = DataTypes.FELT,
        data_len = _calldata_len
    );
    let (local expected_memory: felt*) = alloc();
    let expected_memory_len = Variable.SIZE + _calldata_len;
    memcpy(expected_memory, cast(var_metadata, felt*), Variable.SIZE);
    memcpy(expected_memory + Variable.SIZE, _calldata, _calldata_len);

    let (actual_memory_len, actual_memory) = Memory.init(_calldata_len, _calldata);

    assert_eq(actual_memory_len, expected_memory_len);
    assert_eq(actual_memory[Variable.selector], expected_memory[Variable.selector]);
    assert_eq(actual_memory[Variable.protected], expected_memory[Variable.protected]);
    assert_eq(actual_memory[Variable.type], expected_memory[Variable.type]);
    assert_eq(actual_memory[Variable.data_len], expected_memory[Variable.data_len]);
    assert_eq(actual_memory[Variable.data_len + 1], expected_memory[Variable.data_len + 1]);
    assert_eq(actual_memory[Variable.data_len + 2], expected_memory[Variable.data_len + 2]);
    assert_eq(actual_memory[Variable.data_len + 3], expected_memory[Variable.data_len + 3]);
    assert_eq(actual_memory[Variable.data_len + 4], expected_memory[Variable.data_len + 4]);
    assert_eq(actual_memory[Variable.data_len + 5], expected_memory[Variable.data_len + 5]);

    return ();
}
// @external
// func test_get_row_from_matrix_by_index{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
//     alloc_locals;
//     let (local ptr: felt*) = alloc();
//     assert ptr[0] = 3;
//     assert ptr[1] = 11;
//     assert ptr[2] = 12;
//     assert ptr[3] = 13;
//     assert ptr[4] = 2;
//     assert ptr[5] = 21;
//     assert ptr[6] = 22;
//     let (instruction_len, instruction) = _get_row_from_matrix_by_index(0, 7, ptr);
//     assert_eq(instruction_len, 3);
//     assert_eq(instruction[0], 11);
//     assert_eq(instruction[1], 12);
//     assert_eq(instruction[2], 13);
//     let (instruction_len, instruction) = _get_row_from_matrix_by_index(1, 7, ptr);
//     assert_eq(instruction_len, 2);
//     assert_eq(instruction[0], 21);
//     assert_eq(instruction[1], 22);
//     return ();
// }

// /// @dev ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// /// @dev || selector || protected || type || len || x0 || x1 || ... || x_(len-1) ||
// /// @dev ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// @external
// func test_get_row_from_matrix_by_key_on_single_element_in_memory{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
//     alloc_locals;
//     let (local ptr: felt*) = alloc();
//     assert ptr[0] = 123456;
//     assert ptr[1] = FALSE;
//     assert ptr[2] = DataTypes.FELT;
//     assert ptr[3] = 3;
//     assert ptr[4] = 3;
//     assert ptr[5] = 2;
//     assert ptr[6] = 1;
//     let (var_data_len, var_data, flag) = _get_row_from_matrix_by_key(123456, 7, ptr);
//     assert_eq(var_data_len, 3);
//     assert_eq(var_data[0], 3);
//     assert_eq(var_data[1], 2);
//     assert_eq(var_data[2], 1);
//     return ();
// }

// @external
// func test_get_row_from_matrix_by_key_on_multiple_elements_in_memory{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
//     alloc_locals;
//     let (local ptr: felt*) = alloc();
//     assert ptr[0] = 123456;
//     assert ptr[1] = FALSE;
//     assert ptr[2] = DataTypes.FELT;
//     assert ptr[3] = 3;
//     assert ptr[4] = 0;
//     assert ptr[5] = 0;
//     assert ptr[6] = 0;
//     assert ptr[7] = 987654;
//     assert ptr[8] = FALSE;
//     assert ptr[9] = DataTypes.FELT;
//     assert ptr[10] = 3;
//     assert ptr[11] = 0;
//     assert ptr[12] = 0;
//     assert ptr[13] = 0;
//     assert ptr[14] = 345678;
//     assert ptr[15] = FALSE;
//     assert ptr[16] = DataTypes.FELT;
//     assert ptr[17] = 7;
//     assert ptr[18] = 0;
//     assert ptr[19] = 0;
//     assert ptr[20] = 0;
//     assert ptr[21] = 0;
//     assert ptr[22] = 0;
//     assert ptr[23] = 0;
//     assert ptr[24] = 7;
//
//     let (var_data_len, var_data, flag) = _get_row_from_matrix_by_key(123456, 24, ptr);
//     assert_eq(var_data_len, 3);
//     assert_eq(var_data[0], 0);
//     assert_eq(var_data[1], 0);
//     assert_eq(var_data[2], 0);
//
//     let (var_data_len, var_data, flag) = _get_row_from_matrix_by_key(987654, 24, ptr);
//     assert_eq(var_data_len, 3);
//     assert_eq(var_data[0], 0);
//     assert_eq(var_data[1], 0);
//     assert_eq(var_data[2], 0);
//
//     let (var_data_len, var_data, flag) = _get_row_from_matrix_by_key(345678, 24, ptr);
//     assert_eq(var_data_len, 7);
//     assert_eq(var_data[0], 0);
//     assert_eq(var_data[1], 0);
//     assert_eq(var_data[2], 0);
//     assert_eq(var_data[3], 0);
//     assert_eq(var_data[4], 0);
//     assert_eq(var_data[5], 0);
//     assert_eq(var_data[6], 7);
//
//     return ();
// }

// @external
// func test_get_row_from_matrix_by_key_returns_zeros_if_selector_not_found{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
//     alloc_locals;
//     let (local ptr: felt*) = alloc();
//     assert ptr[0] = 123456;
//     assert ptr[1] = FALSE;
//     assert ptr[2] = DataTypes.FELT;
//     assert ptr[3] = 3;
//     assert ptr[4] = 0;
//     assert ptr[5] = 0;
//     assert ptr[6] = 0;
//     assert ptr[7] = 987654;
//     assert ptr[8] = FALSE;
//     assert ptr[9] = DataTypes.FELT;
//     assert ptr[10] = 3;
//     assert ptr[11] = 0;
//     assert ptr[12] = 0;
//     assert ptr[13] = 0;
//     assert ptr[14] = 345678;
//     assert ptr[15] = FALSE;
//     assert ptr[16] = DataTypes.FELT;
//     assert ptr[17] = 7;
//     assert ptr[18] = 0;
//     assert ptr[19] = 0;
//     assert ptr[20] = 0;
//     assert ptr[21] = 0;
//     assert ptr[22] = 0;
//     assert ptr[23] = 0;
//     assert ptr[24] = 7;
//
//     let (var_data_len, var_data, flag) = _get_row_from_matrix_by_key(191919, 24, ptr);
//     assert_eq(var_data_len, 0);
//     assert_eq(flag.selector, 0);
//     assert_eq(flag.protected, 0);
//     assert_eq(flag.type, 0);
//
//     return ();
// }

// @external
// func test_get_row_from_matrix_by_key_returns_zeros_if_memory_is_empty{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
//     alloc_locals;
//     let (local ptr: felt*) = alloc();
//
//     let (var_data_len, var_data, flag) = _get_row_from_matrix_by_key(123456, 0, ptr);
//     assert_eq(var_data_len, 0);
//     assert_eq(flag.selector, 0);
//     assert_eq(flag.protected, 0);
//     assert_eq(flag.type, 0);
//
//     return ();
// }
