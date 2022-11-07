%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location

from src.constants import API
from src.Storage.IFlobDB import IFlobDB
from src.zklang.library import Program, Memory, Function, State
from src.zklang.primitives.core import (
    __ZKLANG__EXEC,
    __ZKLANG__EVENT,
    __ZKLANG__RETURN,
    __ZKLANG__BRANCH,
    __ZKLANG__SET_FUNCTION,
    __ZKLANG__KILL_PROCESS,
    __ZKLANG__START_PROCESS,
    __ZKLANG__ASSERT_ONLY_OWNER,
)

@external
@raw_input
@raw_output
func __default__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    selector: felt, calldata_size: felt, calldata: felt*
) -> (retdata_size: felt, retdata: felt*) {
    alloc_locals;

    let fun = State.get_fun(selector);
    let (program_raw_len, program_raw) = IFlobDB.load(fun.repo_address, fun.program_hash);

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

    with_attr error_message("ZKL-EXEC _pc={_pc} _memory_len={_memory_len}") {
        let instruction = Program.get_instruction(_pc, _program_len, _program);

        let (calldata_len, calldata) = Memory.load_variable_payload(
            instruction.input1.selector, instruction.input2.selector, _memory_len, _memory
        );

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
    __ZKLANG__SET_FUNCTION(Function.SIZE, cast(_fun, felt*));
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
}

// @return Array of registered zklang functions
@view
@raw_output
func __get_function_selectors__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> (retdata_size: felt, retdata: felt*) {
    alloc_locals;
    let (local sel: felt*) = alloc();
    let sel_len = State.load_selectors(sel, 0);
    return (sel_len, sel);
}

@view
func __supports_interface__(_interface_id: felt) -> (res: felt) {
    return (res=FALSE);
}
