#[starknet::interface]
trait IRegisterMachine<T> {
    fn initialize(self: @T) -> u32;
}

#[starknet::contract]
mod registerMachine {

    use debug::PrintTrait;
    use array::ArrayTrait;

    #[storage]
    struct Storage {}

    #[derive(Copy, Drop)]
    struct Instruction {
        target: u32,
        selector: felt252,
        src1: u32,
        src2: u32,
        dest: u32
    }

    #[external(v0)]
    impl RegisterMachine of super::IRegisterMachine<ContractState> {

        fn initialize(self: @ContractState) -> u32 {

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

            let result_registers = exec_loop(program, registers);
            let result_len = result_registers.len();
            let result = *result_registers.at(result_len - 1);
            result
        }
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
            let target = instruction.target;
            let selector = instruction.selector;
            let operand1 = instruction.src1;
            let operand2 = instruction.src2;

            if target == 0 {

                if selector == 'ADD' {
                    let mut val1 = *temp_array.at(operand1);
                    let mut val2 = *temp_array.at(operand2);
                    let mut res = val1 + val2;
                    registers.append(res);
                } else if selector == 'SUB' {
                    let mut val1 = *temp_array.at(operand1);
                    let mut val2 = *temp_array.at(operand2);
                    let mut res = val1 - val2;
                    registers.append(res);
                } else if selector == 'MUL' {
                    let mut val1 = *temp_array.at(operand1);
                    let mut val2 = *temp_array.at(operand2);
                    let mut res = val1 * val2;
                    registers.append(res);
                } else if selector == 'DIV' {
                    let mut val1 = *temp_array.at(operand1);
                    let mut val2 = *temp_array.at(operand2);
                    let mut res = val1 / val2;
                    registers.append(res);
                } else if selector == 'REM' {
                    let mut val1 = *temp_array.at(operand1);
                    let mut val2 = *temp_array.at(operand2);
                    let mut res = val1 % val2;
                    registers.append(res);
                } else {
                    'Selector not supported'.print();
                    break;
                }
            } else {
                'Only internal supported yet'.print();
                break;
            }

            pc += 1;
        };
        registers
    }
}
