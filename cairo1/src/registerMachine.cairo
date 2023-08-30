use debug::PrintTrait;
use array::ArrayTrait;

const ADD: u32 = 1;
const SUB: u32 = 2;
const MUL: u32 = 3;
const DIV: u32 = 4;

#[derive(Copy, Drop)]
struct Instruction {
    operation: u32,
    src1: u32,
    src2: u32,
    dest: u32
}

fn main() {

    let mut program: Array<Instruction> = ArrayTrait::new();
    let i1 = Instruction { operation: ADD, src1: 0, src2: 1, dest: 3 };
    let i2 = Instruction { operation: MUL, src1: 3, src2: 1, dest: 4 };
    let i3 = Instruction { operation: SUB, src1: 4, src2: 2, dest: 5 };
    let i4 = Instruction { operation: DIV, src1: 5, src2: 0, dest: 6 };
    program.append(i1);
    program.append(i2);
    program.append(i3);
    program.append(i4);

    let mut registers: Array<u32> = ArrayTrait::new();
    registers.append(5);
    registers.append(3);
    registers.append(4);

    let result_registers = exec_loop(program, registers);
    let result_len = result_registers.len();
    let result = *result_registers.at(result_len - 1);
    result.print();
}

fn exec_loop(program: Array<Instruction>, mut registers: Array<u32>) -> Array<u32> {

    let mut program_len = program.len();
    let mut pc: usize = 0;

    loop {
        if pc > program_len - 1 {
            break;
        }

        let temp_array = registers.span();

        let instruction = *program.at(pc);
        let operation = instruction.operation;
        let operand1 = instruction.src1;
        let operand2 = instruction.src2;

        if operation == ADD {
            let mut val1 = *temp_array.at(operand1);
            let mut val2 = *temp_array.at(operand2);
            let mut res = val1 + val2;
            registers.append(res);
        } else if operation == SUB {
            let mut val1 = *temp_array.at(operand1);
            let mut val2 = *temp_array.at(operand2);
            let mut res = val1 - val2;
            registers.append(res);
        } else if operation == MUL {
            let mut val1 = *temp_array.at(operand1);
            let mut val2 = *temp_array.at(operand2);
            let mut res = val1 * val2;
            registers.append(res);
        } else if operation == DIV {
            let mut val1 = *temp_array.at(operand1);
            let mut val2 = *temp_array.at(operand2);
            let mut res = val1 / val2;
            registers.append(res);
        } else {
            'Operation not supported'.print();
            break;
        }
        pc += 1;
    };
    registers
}
