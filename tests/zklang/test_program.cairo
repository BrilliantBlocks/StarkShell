%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.memcpy import memcpy

from src.constants import API
from src.zklang.ZKlang import Program, Instruction, Primitive, Variable, DataTypes

from protostar.asserts import assert_eq


@external
func test_get_instruction{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let (local program: felt*) = alloc();
    let program_len = 5 * Instruction.SIZE;

    tempvar instruction_0 = new Instruction(
        Primitive(1, 1), Variable(0, 1, 2, 3), Variable(4, 5, 6, 7),
    );
    tempvar instruction_1 = new Instruction(
        Primitive(2, 2), Variable(8, 9, 10, 11), Variable(12, 13, 14, 15),
    );
    tempvar instruction_2 = new Instruction(
        Primitive(3, 3), Variable(0, 0, -1, 0), Variable(0, 0, 0, 0),
    );
    tempvar instruction_3 = new Instruction(
        Primitive(4, 4), Variable(0, 1, 2, 3), Variable(4, 5, 6, 7),
    );
    tempvar instruction_4 = new Instruction(
        Primitive(5, 5), Variable(8, 9, 10, 11), Variable(12, 13, 14, 15),
    );

    memcpy(program + 0 * Instruction.SIZE, instruction_0, Instruction.SIZE);
    memcpy(program + 1 * Instruction.SIZE, instruction_1, Instruction.SIZE);
    memcpy(program + 2 * Instruction.SIZE, instruction_2, Instruction.SIZE);
    memcpy(program + 3 * Instruction.SIZE, instruction_3, Instruction.SIZE);
    memcpy(program + 4 * Instruction.SIZE, instruction_4, Instruction.SIZE);

    let actual_instruction = Program.get_instruction(0, program_len, program);

    assert_eq(actual_instruction.primitive.class_hash, instruction_0.primitive.class_hash);
    assert_eq(actual_instruction.primitive.selector, instruction_0.primitive.selector);
    assert_eq(actual_instruction.input.selector, instruction_0.input.selector);
    assert_eq(actual_instruction.input.protected, instruction_0.input.protected);
    assert_eq(actual_instruction.input.type, instruction_0.input.type);
    assert_eq(actual_instruction.input.data_len, instruction_0.input.data_len);
    assert_eq(actual_instruction.output.selector, instruction_0.output.selector);
    assert_eq(actual_instruction.output.protected, instruction_0.output.protected);
    assert_eq(actual_instruction.output.type, instruction_0.output.type);
    assert_eq(actual_instruction.output.data_len, instruction_0.output.data_len);

    let actual_instruction = Program.get_instruction(1, program_len, program);

    assert_eq(actual_instruction.primitive.class_hash, instruction_1.primitive.class_hash);
    assert_eq(actual_instruction.primitive.selector, instruction_1.primitive.selector);
    assert_eq(actual_instruction.input.selector, instruction_1.input.selector);
    assert_eq(actual_instruction.input.protected, instruction_1.input.protected);
    assert_eq(actual_instruction.input.type, instruction_1.input.type);
    assert_eq(actual_instruction.input.data_len, instruction_1.input.data_len);
    assert_eq(actual_instruction.output.selector, instruction_1.output.selector);
    assert_eq(actual_instruction.output.protected, instruction_1.output.protected);
    assert_eq(actual_instruction.output.type, instruction_1.output.type);
    assert_eq(actual_instruction.output.data_len, instruction_1.output.data_len);

    let actual_instruction = Program.get_instruction(2, program_len, program);

    assert_eq(actual_instruction.primitive.class_hash, instruction_2.primitive.class_hash);
    assert_eq(actual_instruction.primitive.selector, instruction_2.primitive.selector);
    assert_eq(actual_instruction.input.selector, instruction_2.input.selector);
    assert_eq(actual_instruction.input.protected, instruction_2.input.protected);
    assert_eq(actual_instruction.input.type, instruction_2.input.type);
    assert_eq(actual_instruction.input.data_len, instruction_2.input.data_len);
    assert_eq(actual_instruction.output.selector, instruction_2.output.selector);
    assert_eq(actual_instruction.output.protected, instruction_2.output.protected);
    assert_eq(actual_instruction.output.type, instruction_2.output.type);
    assert_eq(actual_instruction.output.data_len, instruction_2.output.data_len);

    let actual_instruction = Program.get_instruction(3, program_len, program);

    assert_eq(actual_instruction.primitive.class_hash, instruction_3.primitive.class_hash);
    assert_eq(actual_instruction.primitive.selector, instruction_3.primitive.selector);
    assert_eq(actual_instruction.input.selector, instruction_3.input.selector);
    assert_eq(actual_instruction.input.protected, instruction_3.input.protected);
    assert_eq(actual_instruction.input.type, instruction_3.input.type);
    assert_eq(actual_instruction.input.data_len, instruction_3.input.data_len);
    assert_eq(actual_instruction.output.selector, instruction_3.output.selector);
    assert_eq(actual_instruction.output.protected, instruction_3.output.protected);
    assert_eq(actual_instruction.output.type, instruction_3.output.type);
    assert_eq(actual_instruction.output.data_len, instruction_3.output.data_len);

    let actual_instruction = Program.get_instruction(4, program_len, program);

    assert_eq(actual_instruction.primitive.class_hash, instruction_4.primitive.class_hash);
    assert_eq(actual_instruction.primitive.selector, instruction_4.primitive.selector);
    assert_eq(actual_instruction.input.selector, instruction_4.input.selector);
    assert_eq(actual_instruction.input.protected, instruction_4.input.protected);
    assert_eq(actual_instruction.input.type, instruction_4.input.type);
    assert_eq(actual_instruction.input.data_len, instruction_4.input.data_len);
    assert_eq(actual_instruction.output.selector, instruction_4.output.selector);
    assert_eq(actual_instruction.output.protected, instruction_4.output.protected);
    assert_eq(actual_instruction.output.type, instruction_4.output.type);
    assert_eq(actual_instruction.output.data_len, instruction_4.output.data_len);

    return ();
}
