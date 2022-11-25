%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.memcpy import memcpy

from src.zkode.constants import API
from src.zkode.facets.starkshell.structs import Instruction, Primitive, Variable, DataTypes
from src.zkode.facets.starkshell.library import Program

from protostar.asserts import assert_eq

@external
func test_get_instruction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (local program: felt*) = alloc();
    let program_len = 5 * Instruction.SIZE;

    tempvar instruction_0 = new Instruction(
        Primitive(1, 1), Variable(0, 1, 2, 3), Variable(0, 0, 0, 0), Variable(4, 5, 6, 7),
        );
    tempvar instruction_1 = new Instruction(
        Primitive(2, 2), Variable(8, 9, 10, 11), Variable(0, 0, 0, 0), Variable(12, 13, 14, 15),
        );
    tempvar instruction_2 = new Instruction(
        Primitive(3, 3), Variable(0, 0, -1, 0), Variable(0, 0, 0, 0), Variable(0, 0, 0, 0),
        );
    tempvar instruction_3 = new Instruction(
        Primitive(4, 4), Variable(0, 1, 2, 3), Variable(0, 0, 0, 0), Variable(4, 5, 6, 7),
        );
    tempvar instruction_4 = new Instruction(
        Primitive(5, 5), Variable(8, 9, 10, 11), Variable(0, 0, 0, 0), Variable(12, 13, 14, 15),
        );

    memcpy(program + 0 * Instruction.SIZE, instruction_0, Instruction.SIZE);
    memcpy(program + 1 * Instruction.SIZE, instruction_1, Instruction.SIZE);
    memcpy(program + 2 * Instruction.SIZE, instruction_2, Instruction.SIZE);
    memcpy(program + 3 * Instruction.SIZE, instruction_3, Instruction.SIZE);
    memcpy(program + 4 * Instruction.SIZE, instruction_4, Instruction.SIZE);

    let actual_instruction = Program.get_instruction(0, program_len, program);

    assert_eq(actual_instruction.primitive.class_hash, instruction_0.primitive.class_hash);
    assert_eq(actual_instruction.primitive.selector, instruction_0.primitive.selector);
    assert_eq(actual_instruction.input1.selector, instruction_0.input1.selector);
    assert_eq(actual_instruction.input1.protected, instruction_0.input1.protected);
    assert_eq(actual_instruction.input1.type, instruction_0.input1.type);
    assert_eq(actual_instruction.input1.data_len, instruction_0.input1.data_len);
    assert_eq(actual_instruction.input2.selector, instruction_0.input2.selector);
    assert_eq(actual_instruction.input2.protected, instruction_0.input2.protected);
    assert_eq(actual_instruction.input2.type, instruction_0.input2.type);
    assert_eq(actual_instruction.input2.data_len, instruction_0.input2.data_len);
    assert_eq(actual_instruction.output.selector, instruction_0.output.selector);
    assert_eq(actual_instruction.output.protected, instruction_0.output.protected);
    assert_eq(actual_instruction.output.type, instruction_0.output.type);
    assert_eq(actual_instruction.output.data_len, instruction_0.output.data_len);

    let actual_instruction = Program.get_instruction(1, program_len, program);

    assert_eq(actual_instruction.primitive.class_hash, instruction_1.primitive.class_hash);
    assert_eq(actual_instruction.primitive.selector, instruction_1.primitive.selector);
    assert_eq(actual_instruction.input1.selector, instruction_1.input1.selector);
    assert_eq(actual_instruction.input1.protected, instruction_1.input1.protected);
    assert_eq(actual_instruction.input1.type, instruction_1.input1.type);
    assert_eq(actual_instruction.input1.data_len, instruction_1.input1.data_len);
    assert_eq(actual_instruction.input2.selector, instruction_1.input2.selector);
    assert_eq(actual_instruction.input2.protected, instruction_1.input2.protected);
    assert_eq(actual_instruction.input2.type, instruction_1.input2.type);
    assert_eq(actual_instruction.input2.data_len, instruction_1.input2.data_len);
    assert_eq(actual_instruction.output.selector, instruction_1.output.selector);
    assert_eq(actual_instruction.output.protected, instruction_1.output.protected);
    assert_eq(actual_instruction.output.type, instruction_1.output.type);
    assert_eq(actual_instruction.output.data_len, instruction_1.output.data_len);

    let actual_instruction = Program.get_instruction(2, program_len, program);

    assert_eq(actual_instruction.primitive.class_hash, instruction_2.primitive.class_hash);
    assert_eq(actual_instruction.primitive.selector, instruction_2.primitive.selector);
    assert_eq(actual_instruction.input1.selector, instruction_2.input1.selector);
    assert_eq(actual_instruction.input1.protected, instruction_2.input1.protected);
    assert_eq(actual_instruction.input1.type, instruction_2.input1.type);
    assert_eq(actual_instruction.input1.data_len, instruction_2.input1.data_len);
    assert_eq(actual_instruction.input2.selector, instruction_2.input2.selector);
    assert_eq(actual_instruction.input2.protected, instruction_2.input2.protected);
    assert_eq(actual_instruction.input2.type, instruction_2.input2.type);
    assert_eq(actual_instruction.input2.data_len, instruction_2.input2.data_len);
    assert_eq(actual_instruction.output.selector, instruction_2.output.selector);
    assert_eq(actual_instruction.output.protected, instruction_2.output.protected);
    assert_eq(actual_instruction.output.type, instruction_2.output.type);
    assert_eq(actual_instruction.output.data_len, instruction_2.output.data_len);

    let actual_instruction = Program.get_instruction(3, program_len, program);

    assert_eq(actual_instruction.primitive.class_hash, instruction_3.primitive.class_hash);
    assert_eq(actual_instruction.primitive.selector, instruction_3.primitive.selector);
    assert_eq(actual_instruction.input1.selector, instruction_3.input1.selector);
    assert_eq(actual_instruction.input1.protected, instruction_3.input1.protected);
    assert_eq(actual_instruction.input1.type, instruction_3.input1.type);
    assert_eq(actual_instruction.input1.data_len, instruction_3.input1.data_len);
    assert_eq(actual_instruction.input2.selector, instruction_3.input2.selector);
    assert_eq(actual_instruction.input2.protected, instruction_3.input2.protected);
    assert_eq(actual_instruction.input2.type, instruction_3.input2.type);
    assert_eq(actual_instruction.input2.data_len, instruction_3.input2.data_len);
    assert_eq(actual_instruction.output.selector, instruction_3.output.selector);
    assert_eq(actual_instruction.output.protected, instruction_3.output.protected);
    assert_eq(actual_instruction.output.type, instruction_3.output.type);
    assert_eq(actual_instruction.output.data_len, instruction_3.output.data_len);

    let actual_instruction = Program.get_instruction(4, program_len, program);

    assert_eq(actual_instruction.primitive.class_hash, instruction_4.primitive.class_hash);
    assert_eq(actual_instruction.primitive.selector, instruction_4.primitive.selector);
    assert_eq(actual_instruction.input1.selector, instruction_4.input1.selector);
    assert_eq(actual_instruction.input1.protected, instruction_4.input1.protected);
    assert_eq(actual_instruction.input1.type, instruction_4.input1.type);
    assert_eq(actual_instruction.input1.data_len, instruction_4.input1.data_len);
    assert_eq(actual_instruction.input2.selector, instruction_4.input2.selector);
    assert_eq(actual_instruction.input2.protected, instruction_4.input2.protected);
    assert_eq(actual_instruction.input2.type, instruction_4.input2.type);
    assert_eq(actual_instruction.input2.data_len, instruction_4.input2.data_len);
    assert_eq(actual_instruction.output.selector, instruction_4.output.selector);
    assert_eq(actual_instruction.output.protected, instruction_4.output.protected);
    assert_eq(actual_instruction.output.type, instruction_4.output.type);
    assert_eq(actual_instruction.output.data_len, instruction_4.output.data_len);

    return ();
}

@external
func test_validate_reverts_on_non_boolean_protected{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    let (local program: felt*) = alloc();
    let program_len = 5 * Instruction.SIZE;

    tempvar instruction_0 = new Instruction(
        Primitive(1, 1), Variable(0, 1, 1, 0), Variable(0, 0, 0, 0), Variable(0, 0, 0, 0),
        );
    tempvar instruction_1 = new Instruction(
        Primitive(2, 2), Variable(1, 0, 1, 1), Variable(0, 0, 0, 0), Variable(0, 1, 1, 1),
        );
    tempvar instruction_2 = new Instruction(
        Primitive(3, 3), Variable(0, 0, 1, 0), Variable(0, 0, 0, 0), Variable(0, 3, 0, 0),
        );
    tempvar instruction_3 = new Instruction(
        Primitive(4, 4), Variable(0, 1, 1, 1), Variable(0, 0, 0, 0), Variable(1, 0, 0, 1),
        );
    tempvar instruction_4 = new Instruction(
        Primitive(5, 5), Variable(1, 0, 1, 1), Variable(0, 0, 0, 0), Variable(1, 1, 1, 1),
        );

    memcpy(program + 0 * Instruction.SIZE, instruction_0, Instruction.SIZE);
    memcpy(program + 1 * Instruction.SIZE, instruction_1, Instruction.SIZE);
    memcpy(program + 2 * Instruction.SIZE, instruction_2, Instruction.SIZE);
    memcpy(program + 3 * Instruction.SIZE, instruction_3, Instruction.SIZE);
    memcpy(program + 4 * Instruction.SIZE, instruction_4, Instruction.SIZE);

    %{ expect_revert(error_message="CORRUPT CODE") %}
    Program.validate(program_len, program);

    return ();
}

@external
func test_validate_reverts_on_unknown_type_key{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    let (local program: felt*) = alloc();
    let program_len = 5 * Instruction.SIZE;

    tempvar instruction_0 = new Instruction(
        Primitive(1, 1), Variable(0, 1, 1, 0), Variable(0, 0, 0, 0), Variable(0, 0, 0, 0),
        );
    tempvar instruction_1 = new Instruction(
        Primitive(2, 2), Variable(1, 0, 1, 1), Variable(0, 0, 0, 0), Variable(0, 1, 1, 1),
        );
    tempvar instruction_2 = new Instruction(
        Primitive(3, 3), Variable(0, 0, 1, 0), Variable(0, 0, 0, 0), Variable(0, 1, 3, 0),
        );
    tempvar instruction_3 = new Instruction(
        Primitive(4, 4), Variable(0, 1, 1, 1), Variable(0, 0, 0, 0), Variable(1, 0, 0, 1),
        );
    tempvar instruction_4 = new Instruction(
        Primitive(5, 5), Variable(1, 0, 1, 1), Variable(0, 0, 0, 0), Variable(1, 1, 1, 1),
        );

    memcpy(program + 0 * Instruction.SIZE, instruction_0, Instruction.SIZE);
    memcpy(program + 1 * Instruction.SIZE, instruction_1, Instruction.SIZE);
    memcpy(program + 2 * Instruction.SIZE, instruction_2, Instruction.SIZE);
    memcpy(program + 3 * Instruction.SIZE, instruction_3, Instruction.SIZE);
    memcpy(program + 4 * Instruction.SIZE, instruction_4, Instruction.SIZE);

    %{ expect_revert(error_message="CORRUPT CODE") %}
    Program.validate(program_len, program);

    return ();
}

@external
func test_validate_returns_nothing_on_anything_else{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    let (local program: felt*) = alloc();
    let program_len = 5 * Instruction.SIZE;

    tempvar instruction_0 = new Instruction(
        Primitive(1, 1), Variable(0, 1, 1, 0), Variable(0, 0, 0, 0), Variable(0, 0, 0, 0),
        );
    tempvar instruction_1 = new Instruction(
        Primitive(2, 2), Variable(1, 0, 1, 1), Variable(0, 0, 0, 0), Variable(0, 1, 1, 1),
        );
    tempvar instruction_2 = new Instruction(
        Primitive(3, 3), Variable(0, 0, 1, 0), Variable(0, 0, 0, 0), Variable(0, 1, 1, 0),
        );
    tempvar instruction_3 = new Instruction(
        Primitive(4, 4), Variable(0, 1, 1, 1), Variable(0, 0, 0, 0), Variable(1, 0, 0, 1),
        );
    tempvar instruction_4 = new Instruction(
        Primitive(5, 5), Variable(1, 0, 1, 1), Variable(0, 0, 0, 0), Variable(1, 1, 1, 1),
        );

    memcpy(program + 0 * Instruction.SIZE, instruction_0, Instruction.SIZE);
    memcpy(program + 1 * Instruction.SIZE, instruction_1, Instruction.SIZE);
    memcpy(program + 2 * Instruction.SIZE, instruction_2, Instruction.SIZE);
    memcpy(program + 3 * Instruction.SIZE, instruction_3, Instruction.SIZE);
    memcpy(program + 4 * Instruction.SIZE, instruction_4, Instruction.SIZE);

    Program.validate(program_len, program);

    return ();
}

@external
func test_replace_zero_class_hashes_with_self{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    let (local program: felt*) = alloc();
    let program_len = 5 * Instruction.SIZE;

    tempvar instruction_0 = new Instruction(
        Primitive(0, 1), Variable(0, 1, 1, 0), Variable(0, 0, 0, 0), Variable(0, 0, 0, 0),
        );
    tempvar instruction_1 = new Instruction(
        Primitive(0, 2), Variable(1, 0, 1, 1), Variable(0, 0, 0, 0), Variable(0, 1, 1, 1),
        );
    tempvar instruction_2 = new Instruction(
        Primitive(1, 3), Variable(0, 0, 1, 0), Variable(0, 0, 0, 0), Variable(0, 1, 1, 0),
        );
    tempvar instruction_3 = new Instruction(
        Primitive(4, 4), Variable(0, 1, 1, 1), Variable(0, 0, 0, 0), Variable(1, 0, 0, 1),
        );
    tempvar instruction_4 = new Instruction(
        Primitive(0, 5), Variable(1, 0, 1, 1), Variable(0, 0, 0, 0), Variable(1, 1, 1, 1),
        );

    memcpy(program + 0 * Instruction.SIZE, instruction_0, Instruction.SIZE);
    memcpy(program + 1 * Instruction.SIZE, instruction_1, Instruction.SIZE);
    memcpy(program + 2 * Instruction.SIZE, instruction_2, Instruction.SIZE);
    memcpy(program + 3 * Instruction.SIZE, instruction_3, Instruction.SIZE);
    memcpy(program + 4 * Instruction.SIZE, instruction_4, Instruction.SIZE);

    let (local actual_program: felt*) = alloc();
    let actual_program_len = program_len;
    Program.replace_zero_class_hashes_with_self(actual_program, 123456, program_len, program);

    let actual_instruction = Program.get_instruction(0, actual_program_len, actual_program);
    assert_eq(actual_instruction.primitive.class_hash, 123456);
    assert_eq(actual_instruction.primitive.selector, instruction_0.primitive.selector);
    assert_eq(actual_instruction.input1.selector, instruction_0.input1.selector);
    assert_eq(actual_instruction.input1.protected, instruction_0.input1.protected);
    assert_eq(actual_instruction.input1.type, instruction_0.input1.type);
    assert_eq(actual_instruction.input1.data_len, instruction_0.input1.data_len);
    assert_eq(actual_instruction.input2.selector, instruction_0.input2.selector);
    assert_eq(actual_instruction.input2.protected, instruction_0.input2.protected);
    assert_eq(actual_instruction.input2.type, instruction_0.input2.type);
    assert_eq(actual_instruction.input2.data_len, instruction_0.input2.data_len);
    assert_eq(actual_instruction.output.selector, instruction_0.output.selector);
    assert_eq(actual_instruction.output.protected, instruction_0.output.protected);
    assert_eq(actual_instruction.output.type, instruction_0.output.type);
    assert_eq(actual_instruction.output.data_len, instruction_0.output.data_len);

    let actual_instruction = Program.get_instruction(1, actual_program_len, actual_program);
    assert_eq(actual_instruction.primitive.class_hash, 123456);
    assert_eq(actual_instruction.primitive.selector, instruction_1.primitive.selector);
    assert_eq(actual_instruction.input1.selector, instruction_1.input1.selector);
    assert_eq(actual_instruction.input1.protected, instruction_1.input1.protected);
    assert_eq(actual_instruction.input1.type, instruction_1.input1.type);
    assert_eq(actual_instruction.input1.data_len, instruction_1.input1.data_len);
    assert_eq(actual_instruction.input2.selector, instruction_1.input2.selector);
    assert_eq(actual_instruction.input2.protected, instruction_1.input2.protected);
    assert_eq(actual_instruction.input2.type, instruction_1.input2.type);
    assert_eq(actual_instruction.input2.data_len, instruction_1.input2.data_len);
    assert_eq(actual_instruction.output.selector, instruction_1.output.selector);
    assert_eq(actual_instruction.output.protected, instruction_1.output.protected);
    assert_eq(actual_instruction.output.type, instruction_1.output.type);
    assert_eq(actual_instruction.output.data_len, instruction_1.output.data_len);

    let actual_instruction = Program.get_instruction(2, actual_program_len, actual_program);
    assert_eq(actual_instruction.primitive.class_hash, instruction_2.primitive.class_hash);
    assert_eq(actual_instruction.primitive.selector, instruction_2.primitive.selector);
    assert_eq(actual_instruction.input1.selector, instruction_2.input1.selector);
    assert_eq(actual_instruction.input1.protected, instruction_2.input1.protected);
    assert_eq(actual_instruction.input1.type, instruction_2.input1.type);
    assert_eq(actual_instruction.input1.data_len, instruction_2.input1.data_len);
    assert_eq(actual_instruction.input2.selector, instruction_2.input2.selector);
    assert_eq(actual_instruction.input2.protected, instruction_2.input2.protected);
    assert_eq(actual_instruction.input2.type, instruction_2.input2.type);
    assert_eq(actual_instruction.input2.data_len, instruction_2.input2.data_len);
    assert_eq(actual_instruction.output.selector, instruction_2.output.selector);
    assert_eq(actual_instruction.output.protected, instruction_2.output.protected);
    assert_eq(actual_instruction.output.type, instruction_2.output.type);
    assert_eq(actual_instruction.output.data_len, instruction_2.output.data_len);

    let actual_instruction = Program.get_instruction(3, actual_program_len, actual_program);
    assert_eq(actual_instruction.primitive.class_hash, instruction_3.primitive.class_hash);
    assert_eq(actual_instruction.primitive.selector, instruction_3.primitive.selector);
    assert_eq(actual_instruction.input1.selector, instruction_3.input1.selector);
    assert_eq(actual_instruction.input1.protected, instruction_3.input1.protected);
    assert_eq(actual_instruction.input1.type, instruction_3.input1.type);
    assert_eq(actual_instruction.input1.data_len, instruction_3.input1.data_len);
    assert_eq(actual_instruction.input2.selector, instruction_3.input2.selector);
    assert_eq(actual_instruction.input2.protected, instruction_3.input2.protected);
    assert_eq(actual_instruction.input2.type, instruction_3.input2.type);
    assert_eq(actual_instruction.input2.data_len, instruction_3.input2.data_len);
    assert_eq(actual_instruction.output.selector, instruction_3.output.selector);
    assert_eq(actual_instruction.output.protected, instruction_3.output.protected);
    assert_eq(actual_instruction.output.type, instruction_3.output.type);
    assert_eq(actual_instruction.output.data_len, instruction_3.output.data_len);

    let actual_instruction = Program.get_instruction(4, actual_program_len, actual_program);
    assert_eq(actual_instruction.primitive.class_hash, 123456);
    assert_eq(actual_instruction.primitive.selector, instruction_4.primitive.selector);
    assert_eq(actual_instruction.input1.selector, instruction_4.input1.selector);
    assert_eq(actual_instruction.input1.protected, instruction_4.input1.protected);
    assert_eq(actual_instruction.input1.type, instruction_4.input1.type);
    assert_eq(actual_instruction.input1.data_len, instruction_4.input1.data_len);
    assert_eq(actual_instruction.input2.selector, instruction_4.input2.selector);
    assert_eq(actual_instruction.input2.protected, instruction_4.input2.protected);
    assert_eq(actual_instruction.input2.type, instruction_4.input2.type);
    assert_eq(actual_instruction.input2.data_len, instruction_4.input2.data_len);
    assert_eq(actual_instruction.output.selector, instruction_4.output.selector);
    assert_eq(actual_instruction.output.protected, instruction_4.output.protected);
    assert_eq(actual_instruction.output.type, instruction_4.output.type);
    assert_eq(actual_instruction.output.data_len, instruction_4.output.data_len);

    return ();
}
