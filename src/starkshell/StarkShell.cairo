%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.starknet.common.syscalls import get_contract_address

from src.constants import API
from src.ERC2535.library import Library
from src.Storage.IFlobDB import IFlobDB
from src.starkshell.library import Program, Memory, State
from src.starkshell.structs import Function, Variable
from src.starkshell.primitives.core import (
    __ZKLANG__EVENT,
    __ZKLANG__RETURN,
    __ZKLANG__BRANCH,
    __ZKLANG__SET_FUNCTION,
    __ZKLANG__ASSERT_ONLY_OWNER,
    __ZKLANG__DEPLOY,
    __ZKLANG__NOOP,
    __ZKLANG__CALL_CONTRACT,
    __ZKLANG__FELT_TO_UINT256,
    __ZKLANG__SUM,
)

@external
@raw_input
@raw_output
func __default__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    selector: felt, calldata_size: felt, calldata: felt*
) -> (retdata_size: felt, retdata: felt*) {
    alloc_locals;

    let fun = State.get_fun(selector);

    let (self) = get_contract_address();

    let normalized_repo_address = Library._if_x_is_zero_then_y_else_x(fun.repo_address, self);

    with_attr error_message("LOAD FROM ROOT DIAMOND FAILED") {
        let (program_raw_len, program_raw) = IFlobDB.load(
            normalized_repo_address, fun.program_hash
        );
    }

    local program_len: felt = program_raw[0];
    local program: felt* = program_raw + 1;
    local memory_len: felt = program_raw_len - 1 - program_len;
    local memory: felt* = program_raw + 1 + program_len;

    let (program_len, program) = Program.prepare(selector, program_len, program);
    let (memory_len, memory) = Memory.init(memory_len, memory, calldata_size, calldata);

    let (retdata_size, retdata, _, _) = exec_loop(
        _pc=0, _program_len=program_len, _program=program, _memory_len=memory_len, _memory=memory
    );

    return (retdata_size, retdata);
}

func exec_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _pc: felt, _program_len: felt, _program: felt*, _memory_len: felt, _memory: felt*
) -> (res_len: felt, res: felt*, state_len: felt, state: felt*) {
    alloc_locals;

    with_attr error_message(
            "ZKL-EXEC _pc={_pc} _program_len={_program_len} _memory_len={_memory_len}") {
        let instruction = Program.get_instruction(_pc, _program_len, _program);

        // let (y_len, y) = Memory.load_variable(1735920706216604943978043612916965331422467783673060814787662446889856103197, _memory_len, _memory);
        // if (_pc ==  2) {
        //     local y_len = y_len;
        //     local y0 = y[0];
        //     local y1 = y[1];
        //     local y2 = y[2];
        //     local y3 = y[3];
        //     local y4 = y[4];
        //     local y5 = y[5];
        //     local y6 = y[6];
        //     with_attr error_message("len={y_len} | {y0} {y1} {y2} {y3} {y4} {y5} {y6}") {
        //         assert 1 = 0;
        //     }
        // }
        if (instruction.primitive.selector == API.CORE.__ZKLANG__NOOP and
            instruction.input1.selector == 0) {
            let (var_len, var) = Memory.load_variable(
                instruction.input2.selector, _memory_len, _memory
            );
            let prefix_size = Variable.SIZE - 1;
            with_attr error_message("POP UPDATE ERROR") {
                let (var_len, var) = Memory.pop(var_len - prefix_size, var + prefix_size);
            }
            let (new_memory_len, new_memory) = Memory.update_variable(
                instruction.output.selector, _memory_len, _memory, var[0], var + 1
            );

            return exec_loop(
                _pc=_pc + 1,
                _program_len=_program_len,
                _program=_program,
                _memory_len=new_memory_len,
                _memory=new_memory,
            );
        }

        if (instruction.primitive.selector == API.CORE.__ZKLANG__NOOP and
            instruction.input2.selector == 0) {
            let (var_len, var) = Memory.load_variable(
                instruction.input1.selector, _memory_len, _memory
            );
            let prefix_size = Variable.SIZE - 1;
            with_attr error_message("PUSH UPDATE ERROR") {
                let (var_len, var) = Memory.push(var_len - prefix_size, var + prefix_size);
            }
            let (new_memory_len, new_memory) = Memory.update_variable(
                instruction.output.selector, _memory_len, _memory, var[0], var + 1
            );

            return exec_loop(
                _pc=_pc + 1,
                _program_len=_program_len,
                _program=_program,
                _memory_len=new_memory_len,
                _memory=new_memory,
            );
        }

        let (calldata_len, calldata) = Memory.load_variable_payload(
            instruction.input1.selector, instruction.input2.selector, _memory_len, _memory
        );

        // Temporary fix
        let calldata_len = calldata[0];
        let calldata = calldata + 1;

        // local x_len = calldata_len;
        // if (_pc ==  8) {
        //     local x0 = calldata[0];
        //     local x1 = calldata[1];
        //     local x2 = calldata[2];
        //     // local x3 = calldata[3];
        //     // local x4 = calldata[4];
        //     // local x5 = calldata[5];
        //     // local x6 = calldata[6];
        //     with_attr error_message("BREAKPOINT PRMTV {x_len} {x0} {x1} {x2}") {
        //         assert 1 = 0;
        //     }
        // }

        let (res_len, res) = Program.execute_primitive(
            instruction.primitive, calldata_len, calldata
        );

        if (instruction.primitive.selector == API.CORE.__ZKLANG__RETURN) {
            return (res[0], res + 1, _memory_len, _memory);
        }

        if (instruction.primitive.selector == API.CORE.__ZKLANG__BRANCH) {
            local chosen_pc = res[1];
            return exec_loop(
                _pc=chosen_pc,
                _program_len=_program_len,
                _program=_program,
                _memory_len=_memory_len,
                _memory=_memory,
            );
        }

        // TODO improve error message if var not present
        let (new_memory_len, new_memory) = Memory.update_variable(
            instruction.output.selector, _memory_len, _memory, res_len, res
        );

        return exec_loop(
            _pc=_pc + 1,
            _program_len=_program_len,
            _program=_program,
            _memory_len=new_memory_len,
            _memory=new_memory,
        );
    }
}

@external
func __ZKLANG__EXEC{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _program_len: felt, _program: felt*, _memory_len: felt, _memory: felt*
) -> (res_len: felt, res: felt*) {
    // TODO return state
    let (res_len, res, _, _) = exec_loop(
        _pc=0,
        _program_len=_program_len,
        _program=_program,
        _memory_len=_memory_len,
        _memory=_memory,
    );

    return (res_len, res);
}

// ===============
// Facet Detection
// ===============
@external
func __constructor__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _fun_len: felt, _fun: Function*
) -> () {
    alloc_locals;

    if (_fun_len == 0) {
        return ();
    }
    __ZKLANG__SET_FUNCTION(_fun[0]);
    return __constructor__(_fun_len - 1, _fun + Function.SIZE);
}

@external
func __destructor__() -> () {
    return ();
}

@view
@raw_output
func __API__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    retdata_size: felt, retdata: felt*
) {
    let (func_selectors) = get_label_location(selectors_start);
    return (retdata_size=7, retdata=cast(func_selectors, felt*));

    selectors_start:
    dw API.CORE.__ZKLANG__RETURN;
    dw API.CORE.__ZKLANG__BRANCH;
    dw API.CORE.__ZKLANG__EVENT;
    dw API.CORE.__ZKLANG__REVERT;
    dw API.CORE.__ZKLANG__SET_FUNCTION;
    dw API.CORE.__ZKLANG__EXEC;
    dw API.CORE.__ZKLANG__ASSERT_ONLY_OWNER;
    dw API.CORE.__ZKLANG__DEPLOY;
}

// @return Array of registered zklang functions
@view
@raw_output
func __pub_func__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    retdata_size: felt, retdata: felt*
) {
    alloc_locals;
    let (local sel: felt*) = alloc();
    let sel_len = State.load_selectors(sel, 0);
    return (sel_len, sel);
}

@view
func __supports_interface__(_interface_id: felt) -> (res: felt) {
    return (res=FALSE);
}
