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
