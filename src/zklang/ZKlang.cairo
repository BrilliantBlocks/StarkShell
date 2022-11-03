%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location

from src.constants import API, FUNCTION_SELECTORS
from src.Storage.IFlobDB import IFlobDB
from src.zklang.library import Program, Memory, Function, Primitive, Variable, Instruction, State


@event
func __ZKLANG__EMIT(_key: felt, _val_len: felt, _val: felt*){
}

@external
@raw_input
@raw_output
func __default__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(selector: felt, calldata_size: felt, calldata: felt*) -> (retdata_size: felt, retdata: felt*) {
    alloc_locals;

    let fun = State.get_fun(selector);
    let (program_raw_len, program_raw) = IFlobDB.load(fun.repo_address, fun.program_hash);
    let (program_len, program) = Program.prepare(selector, program_raw_len, program_raw);
    let (memory_len, memory) = Memory.init(calldata_size, calldata);

    let (retdata_size, retdata) = exec_loop(
        _pc = 0,
        _program_len = program_len,
        _program = program,
        _memory_len = memory_len,
        _memory = memory,
    );

    return (retdata_size, retdata);
}

func exec_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _pc: felt,
        _program_len: felt,
        _program: felt*,
        _memory_len: felt,
        _memory: felt*,
    ) -> (res_len: felt, res: felt*) {
    alloc_locals;

    let instruction = Program.get_instruction(_pc, _program_len, _program);
    let (calldata_len, calldata) = Memory.load_variable_payload(instruction.input.selector, _memory_len, _memory);
    let (res_len, res) = Program.execute_primitive(instruction.primitive, calldata_len, calldata);

    if (instruction.primitive.selector == API.CORE.__ZKLANG__RETURN) {
        return (res_len, res);
    }

    if (instruction.primitive.selector == API.CORE.__ZKLANG__BRANCH) {
        let chosen_pc = res[0];
        return exec_loop(
            _pc = chosen_pc,
            _program_len = _program_len,
            _program = _program,
            _memory_len = _memory_len,
            _memory = _memory,
        );
    }

    let (new_memory_len, new_memory) = Memory.update_variable(instruction.output, _memory_len, _memory, res_len, res);

    return exec_loop(
        _pc = _pc + 1,
        _program_len = _program_len,
        _program = _program,
        _memory_len = _memory_len,
        _memory = _memory,
    );
}

// =================
// Zklang Primitives
// =================
@external
func __ZKLANG__RETURN{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(res_len: felt, res: felt*) -> (res_len: felt, res: felt*) {
    return (res_len, res);
}

@external
func __ZKLANG__BRANCH{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_var: felt, _pc_if_true: felt, _pc_if_false: felt) -> (res: felt) {
    if (_var == TRUE) {
        return (res=_pc_if_true);
    }
    return (res=_pc_if_false);
}

@external
func __ZKLANG__EVENT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_key: felt, _val_len: felt, _val: felt*) {
    __ZKLANG__EMIT.emit(_key, _val_len, _val);
    return ();
}

@view
func __ZKLANG__REVERT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    with_attr error_message("__ZKLANG__REVERT") {
        assert 1 = 0;
    }
    return ();
}

@external
func __ZKLANG__SET_FUNCTION{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(_function: Function) -> () {
    State.set_fun(_function);
    return ();
}

@external
func __ZKLANG__EXEC{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(_program_len: felt, _program: felt*) {
    // TODO exec loop for code
    // TODO emit state
    // TODO store hash of state
    return ();
}

// ===============
// Facet Detection
// ===============
@external
func __constructor__{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(_fun_len: felt, _fun: Function*) -> () {
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
func __API__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (retdata_size: felt, retdata: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (retdata_size=5, retdata=cast(func_selectors, felt*));

    selectors_start:
    dw API.CORE.__ZKLANG__RETURN;
    dw API.CORE.__ZKLANG__BRANCH;
    dw API.CORE.__ZKLANG__EVENT;
    dw API.CORE.__ZKLANG__REVERT;
    dw API.CORE.__ZKLANG__SET_FUNCTION;
    dw API.CORE.__ZKLANG__EXEC;
}

/// @return Array of registered zklang functions
@view
@raw_output
func __get_function_selectors__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (retdata_size: felt, retdata: felt*) {
    alloc_locals;
    let (local sel: felt*) = alloc();
    let sel_len = State.load_selectors(sel, 0);
    return (sel_len, sel);
}

@view
func __supports_interface__(_interface_id: felt) -> (res: felt) {
    return (res=FALSE);
}
