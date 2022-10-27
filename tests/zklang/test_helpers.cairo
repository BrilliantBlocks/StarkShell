%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin

from src.zklang.ZKlang import _filter_instruction

from protostar.asserts import assert_eq


@external
func test_filter_instruction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    let (local ptr: felt*) = alloc();
    assert ptr[0] = 3;
    assert ptr[1] = 11;
    assert ptr[2] = 12;
    assert ptr[3] = 13;
    assert ptr[4] = 2;
    assert ptr[5] = 21;
    assert ptr[6] = 22;
    let (instruction_len, instruction) = _filter_instruction(0, 7, ptr);
    assert_eq(instruction_len, 3);
    assert_eq(instruction[0], 11);
    assert_eq(instruction[1], 12);
    assert_eq(instruction[2], 13);
    let (instruction_len, instruction) = _filter_instruction(1, 7, ptr);
    assert_eq(instruction_len, 2);
    assert_eq(instruction[0], 21);
    assert_eq(instruction[1], 22);
    return ();
}
