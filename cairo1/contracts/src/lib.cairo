#[derive(Copy, Drop, Serde)]
struct Instruction {
    target: u32,
    selector: felt252,
    src1: u32,
    src2: u32,
    dest: u32
}

#[starknet::interface]
trait IRegisterMachine<TContractState> {
    fn execute(self: @TContractState, program: Array<Instruction>, registers: Array<u32>) -> felt252;
}

#[starknet::contract]
mod registerMachine {
    
    use super::{IRegisterMachine, Instruction};

    #[storage]
    struct Storage {}

    #[external(v0)]
    impl RegisterMachine of IRegisterMachine<ContractState> {

        fn execute(self: @ContractState, program: Array<Instruction>, registers: Array<u32>) -> felt252 {

            let result = exec_loop(program, registers);
            result
        }
    }

    fn exec_loop(program: Array<Instruction>, mut registers: Array<u32>) -> felt252 {

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
                    'Selector not supported';
                    break;
                }
            } else {
                'Only internal supported yet';
                break;
            }

            pc += 1;
        };

        let registers_len = registers.len();
        let last_register = *registers.at(registers_len - 1);
        let last_register_felt252: felt252 = last_register.into();
        last_register_felt252
    }
}
