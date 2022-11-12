%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.memcpy import memcpy

from src.zklang.primitives.core import __ZKLANG__MERGE_VARS
from src.zklang.structs import DataTypes, Variable

from protostar.asserts import assert_eq, assert_not_eq

@external
func test_merge_vars_on_two_non_empty_vars{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    tempvar var0 = Variable(0x6, 0, 0, 2);
    tempvar var1 = Variable(0x7, 0, 0, 3);

    tempvar calldata = new (
        var0, 11, 12,
        var1, 21, 22, 23,
        );
    tempvar payload_size = var0.data_len + var1.data_len;
    tempvar calldata_len = 2 * Variable.SIZE + payload_size;

    let (actual_res_len, actual_res) = __ZKLANG__MERGE_VARS(calldata_len, calldata);
    assert_eq(actual_res_len, 5);
    assert_eq(actual_res[0], 11);
    assert_eq(actual_res[1], 12);
    assert_eq(actual_res[2], 21);
    assert_eq(actual_res[3], 22);
    assert_eq(actual_res[4], 23);

    return ();
}

@external
func test_merge_vars_on_empty_and_non_empty_vars{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    tempvar var0 = Variable(0x6, 0, 0, 0);
    tempvar var1 = Variable(0x7, 0, 0, 3);

    tempvar calldata = new (
        var0,
        var1, 21, 22, 23,
        );
    tempvar payload_size = var0.data_len + var1.data_len;
    tempvar calldata_len = 2 * Variable.SIZE + payload_size;

    let (actual_res_len, actual_res) = __ZKLANG__MERGE_VARS(calldata_len, calldata);
    assert_eq(actual_res_len, 3);
    assert_eq(actual_res[0], 21);
    assert_eq(actual_res[1], 22);
    assert_eq(actual_res[2], 23);

    return ();
}

@external
func test_merge_vars_on_two_empty_vars{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    tempvar var0 = Variable(0x6, 0, 0, 0);
    tempvar var1 = Variable(0x7, 0, 0, 0);

    tempvar calldata = new (
        var0,
        var1,
        );
    tempvar payload_size = var0.data_len + var1.data_len;
    tempvar calldata_len = 2 * Variable.SIZE + payload_size;

    let (actual_res_len, actual_res) = __ZKLANG__MERGE_VARS(calldata_len, calldata);
    assert_eq(actual_res_len, 0);

    return ();
}
