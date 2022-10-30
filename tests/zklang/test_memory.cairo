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

@external
func test_len_without_left_memory_returns_expected_len_non_empty_left{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    tempvar var0 = new Variable(
        selector = 3,
        protected = FALSE,
        type = DataTypes.FELT,
        data_len = 5,
            );
    tempvar var0_data = new (4, 3, 2, 1, 0);

    tempvar var1 = new Variable(
        selector = 6,
        protected = FALSE,
        type = DataTypes.BOOL,
        data_len = 1,
            );
    tempvar var1_data = new (TRUE);

    tempvar var2 = new Variable(
        selector = 0,
        protected = TRUE,
        type = DataTypes.BOOL,
        data_len = 3,
            );
    tempvar var2_data = new (TRUE, FALSE, TRUE);

    let (local memory: felt*) = alloc();
    let memory_len = 3 * Variable.SIZE + var0.data_len + var1.data_len + var2.data_len;

    memcpy(memory + 0 * Variable.SIZE, var0, Variable.SIZE);
    memcpy(memory + 1 * Variable.SIZE, var0_data, var0.data_len);
    memcpy(memory + 1 * Variable.SIZE + var0.data_len, var1, Variable.SIZE);
    memcpy(memory + 2 * Variable.SIZE + var0.data_len, var1_data, var1.data_len);
    memcpy(memory + 2 * Variable.SIZE + var0.data_len + var1.data_len, var2, Variable.SIZE);
    memcpy(memory + 3 * Variable.SIZE + var0.data_len + var1.data_len, var2_data, var2.data_len);

    let actual_memory_len_without_left = Memory.len_without_left_memory(3, memory_len, memory);
    let expected_memory_len_without_left = memory_len - Variable.SIZE - var0.data_len;
    assert_eq(actual_memory_len_without_left, expected_memory_len_without_left);


    let actual_memory_len_without_left = Memory.len_without_left_memory(6, memory_len, memory);
    let expected_memory_len_without_left = memory_len - 2 * Variable.SIZE - var0.data_len - var1.data_len;
    assert_eq(actual_memory_len_without_left, expected_memory_len_without_left);

    let actual_memory_len_without_left = Memory.len_without_left_memory(0, memory_len, memory);
    let expected_memory_len_without_left = memory_len - 3 * Variable.SIZE - var0.data_len - var1.data_len - var2.data_len;
    assert_eq(actual_memory_len_without_left, expected_memory_len_without_left);

    return ();
}

@external
func test_len_without_left_memory_returns_zero_if_memory_is_empty{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    let (local memory: felt*) = alloc();
    let memory_len = 0;

    let actual_memory_len_without_left = Memory.len_without_left_memory(3, memory_len, memory);
    let expected_memory_len_without_left = 0;
    assert_eq(actual_memory_len_without_left, expected_memory_len_without_left);

    return ();
}

@external
func test_len_without_left_memory_returns_zero_if_no_data_in_memory{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    tempvar var0 = new Variable(
        selector = 3,
        protected = FALSE,
        type = DataTypes.FELT,
        data_len = 5,
            );
    tempvar var0_data = new (4, 3, 2, 1, 0);

    tempvar var1 = new Variable(
        selector = 6,
        protected = FALSE,
        type = DataTypes.BOOL,
        data_len = 1,
            );
    tempvar var1_data = new (TRUE);

    tempvar var2 = new Variable(
        selector = 0,
        protected = TRUE,
        type = DataTypes.BOOL,
        data_len = 3,
            );
    tempvar var2_data = new (TRUE, FALSE, TRUE);

    let (local memory: felt*) = alloc();
    let memory_len = 3 * Variable.SIZE + var0.data_len + var1.data_len + var2.data_len;

    memcpy(memory + 0 * Variable.SIZE, var0, Variable.SIZE);
    memcpy(memory + 1 * Variable.SIZE, var0_data, var0.data_len);
    memcpy(memory + 1 * Variable.SIZE + var0.data_len, var1, Variable.SIZE);
    memcpy(memory + 2 * Variable.SIZE + var0.data_len, var1_data, var1.data_len);
    memcpy(memory + 2 * Variable.SIZE + var0.data_len + var1.data_len, var2, Variable.SIZE);
    memcpy(memory + 3 * Variable.SIZE + var0.data_len + var1.data_len, var2_data, var2.data_len);

    let actual_memory_len_without_left = Memory.len_without_left_memory(1, memory_len, memory);
    let expected_memory_len_without_left = 0;
    assert_eq(actual_memory_len_without_left, expected_memory_len_without_left);

    return ();
}

@external
func test_{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    return ();
}
