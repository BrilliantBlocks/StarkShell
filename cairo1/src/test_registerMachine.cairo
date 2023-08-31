use starkshell::registerMachine::{Instruction, execute};

#[test]
#[available_gas(20000000)]
fn test_add() {

    // 5 + 3

    let mut program: Array<Instruction> = ArrayTrait::new();
    let i1 = Instruction { target: 0, selector: 'ADD', src1: 0, src2: 1, dest: 2 };
    program.append(i1);

    let mut registers: Array<u32> = ArrayTrait::new();
    registers.append(5);
    registers.append(3);

    let result = execute(program, registers);
    assert(result == 8, 'result is not 8');
}

#[test]
#[available_gas(20000000)]
fn test_sub() {

    // 5 - 3

    let mut program: Array<Instruction> = ArrayTrait::new();
    let i1 = Instruction { target: 0, selector: 'SUB', src1: 0, src2: 1, dest: 2 };
    program.append(i1);

    let mut registers: Array<u32> = ArrayTrait::new();
    registers.append(5);
    registers.append(3);

    let result = execute(program, registers);
    assert(result == 2, 'result is not 2');
}

#[test]
#[available_gas(20000000)]
fn test_mul() {

    // 5 * 3

    let mut program: Array<Instruction> = ArrayTrait::new();
    let i1 = Instruction { target: 0, selector: 'MUL', src1: 0, src2: 1, dest: 2 };
    program.append(i1);

    let mut registers: Array<u32> = ArrayTrait::new();
    registers.append(5);
    registers.append(3);

    let result = execute(program, registers);
    assert(result == 15, 'result is not 15');
}

#[test]
#[available_gas(20000000)]
fn test_div() {

    // 15 / 3

    let mut program: Array<Instruction> = ArrayTrait::new();
    let i1 = Instruction { target: 0, selector: 'DIV', src1: 0, src2: 1, dest: 2 };
    program.append(i1);

    let mut registers: Array<u32> = ArrayTrait::new();
    registers.append(15);
    registers.append(3);

    let result = execute(program, registers);
    assert(result == 5, 'result is not 5');
}

#[test]
#[available_gas(20000000)]
fn test_rem() {

    // 15 % 4

    let mut program: Array<Instruction> = ArrayTrait::new();
    let i1 = Instruction { target: 0, selector: 'DIV', src1: 0, src2: 1, dest: 2 };
    program.append(i1);

    let mut registers: Array<u32> = ArrayTrait::new();
    registers.append(15);
    registers.append(4);

    let result = execute(program, registers);
    assert(result == 3, 'result is not 3');
}

#[test]
#[available_gas(20000000)]
fn test_all() {

    // (((5 + 3) * 3 - 4) / 5) % 3

    let mut program: Array<Instruction> = ArrayTrait::new();
    let i1 = Instruction { target: 0, selector: 'ADD', src1: 0, src2: 1, dest: 3 };
    let i2 = Instruction { target: 0, selector: 'MUL', src1: 3, src2: 1, dest: 4 };
    let i3 = Instruction { target: 0, selector: 'SUB', src1: 4, src2: 2, dest: 5 };
    let i4 = Instruction { target: 0, selector: 'DIV', src1: 5, src2: 0, dest: 6 };
    let i5 = Instruction { target: 0, selector: 'REM', src1: 6, src2: 1, dest: 7 };
    program.append(i1);
    program.append(i2);
    program.append(i3);
    program.append(i4);
    program.append(i5);

    let mut registers: Array<u32> = ArrayTrait::new();
    registers.append(5);
    registers.append(3);
    registers.append(4);

    let result = execute(program, registers);
    assert(result == 1, 'result is not 1');
}