%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.registers import get_label_location
from starkware.starknet.common.syscalls import get_contract_address, library_call

from src.constants import API, FUNCTION_SELECTORS
from src.ERC2535.IDiamond import IDiamond
from src.ERC2535.library import Library
from src.Storage.IFlobDB import IFlobDB
from src.zklang.library import Program, Memory, Primitive, Variable, Instruction, DataTypes


@event
func __ZKLANG__EMIT(_key: felt, _val_len: felt, _val: felt*){
}

@storage_var
func fun_selector_index_(i: felt) -> (fun_selector: felt) {
}

@storage_var
func fun_selector_program_hash_mapping_(fun_selector: felt) -> (program_hash: felt) {
}

@storage_var
func program_hash_repo_address_mapping_(program_hash: felt) -> (repo_address: felt) {
}

@external
@raw_input
@raw_output
func __default__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(selector: felt, calldata_size: felt, calldata: felt*) -> (retdata_size: felt, retdata: felt*) {
    alloc_locals;
    // Prepare
    let (program_hash) = fun_selector_program_hash_mapping_.read(selector);
    let (repo_address) = program_hash_repo_address_mapping_.read(program_hash);
    let (program_len, program) = IFlobDB.load(repo_address, program_hash);
    let (this_diamond) = get_contract_address();
    let (this_zklang) = IDiamond.facetAddress(this_diamond, selector);

    // Load calldata into memory
    let (memory_len, memory) = Memory.init(calldata_size, calldata);

    // Execute
    let (retdata_size, retdata) = exec_loop(
        _pc = 0,
        _program_len = program_len,
        _program = program,
        _memory_len = memory_len,
        _memory = memory,
        _this_zklang = this_zklang,
    );

    return (retdata_size, retdata);
}

@external
func exec_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _pc: felt,
        _program_len: felt,
        _program: felt*,
        _memory_len: felt,
        _memory: felt*,
        _this_zklang: felt,
    ) -> (res_len: felt, res: felt*) {
    alloc_locals;

    let curr_instruction = Program.get_instruction(_pc, _program_len, _program);

    // Get input variable from memory
    let (l_len, l, v_len, v, r_len, r) = _split_memory(curr_instruction.input.selector, _memory_len, _memory);

    // This zklang facet or other facet?
    let facet_hash = Library._if_x_is_zero_then_y_else_x(curr_instruction.primitive.class_hash, _this_zklang);

    // Execute primitive
    let (res_len, res) = library_call(
        class_hash=facet_hash,
        function_selector=curr_instruction.primitive.selector,
        calldata_size=v_len - Variable.SIZE,
        calldata=v + Variable.SIZE,
    );

    if (curr_instruction.primitive.selector == API.CORE.__ZKLANG__RETURN) {
        return (res_len, res);
    }

    if (curr_instruction.primitive.selector == API.CORE.__ZKLANG__GOTO) {
        // Continue execution at specified pc
        return exec_loop(
            _pc = res[0],
            _program_len = _program_len,
            _program = _program,
            _memory_len = _memory_len,
            _memory = _memory,
            _this_zklang = _this_zklang,
        );
    }

    // Update memory
    let (l_len, l, v_len, v, r_len, r) = _split_memory(curr_instruction.output.selector, _memory_len, _memory);

    with_attr error_message("CONSTS ARE IMMUTABLE") {
        assert v[Variable.protected] = FALSE;
    }

    let (local new_memory: felt*) = alloc();
    memcpy(new_memory, l, l_len);
    memcpy(new_memory + l_len, v, Variable.SIZE);
    memcpy(new_memory + l_len + Variable.SIZE, res, res_len);
    memcpy(new_memory + l_len + Variable.SIZE + res_len, r, r_len);
    let new_memory_len = l_len + Variable.SIZE + res_len + r_len;

    // Exec next instruction
    return exec_loop(
        _pc = _pc + 1,
        _program_len = _program_len,
        _program = _program,
        _memory_len = _memory_len,
        _memory = _memory,
        _this_zklang = _this_zklang,
    );
}
    
func _get_row_from_matrix_by_index{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_n: felt, _matrix_len: felt, _matrix: felt*) -> (res_len: felt, res: felt*) {
    alloc_locals;

    if (_n == 0) {
        return (_matrix[0], _matrix + 1);
    }
    let next_n = _n - 1;
    let next_row_len = _matrix_len - _matrix[0] - 1;
    let next_row = _matrix + _matrix[0] + 1;

    return _get_row_from_matrix_by_index(next_n, next_row_len, next_row);
}

func _split_memory{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _var_selector: felt, _memory_len: felt, _memory: felt*
    ) -> (left_memory_len: felt, left_memory: felt*, var_len: felt, var: felt*, right_memory_len: felt, right_memory: felt*) {
    alloc_locals;
    let memory_len_without_left = _memory_len_without_left(_var_selector, _memory_len, _memory);
    let left_memory_len = _memory_len - memory_len_without_left;
    let var_len = _memory[left_memory_len + Variable.SIZE] + Variable.SIZE;
    let right_memory_len = _memory_len - left_memory_len - var_len;

    let (local left_memory: felt*) = alloc();
    let (local var: felt*) = alloc();
    let (local right_memory: felt*) = alloc();

    memcpy(left_memory, _memory, left_memory_len);
    memcpy(var, _memory + left_memory_len + 1, var_len);
    memcpy(right_memory, _memory + left_memory_len + right_memory_len + 1, right_memory_len);

    return (left_memory_len, left_memory, var_len, var, right_memory_len, right_memory);
}

func _memory_len_without_left{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_key: felt, _matrix_len: felt, _matrix: felt*) -> felt {
    alloc_locals;

    // No data in memory
    if (_matrix_len == 0) {
        return 0;
    }
    
    // Variable not in memory
    if (_matrix_len == -1) {
        return 0;
    }

    if (_matrix[0] == _key) {
        return _matrix_len;
    }

    let next_row_len = _matrix_len - Variable.SIZE - _matrix[Variable.SIZE];
    let next_row = _matrix + Variable.SIZE + _matrix[Variable.SIZE];

    return _memory_len_without_left(_key, next_row_len, next_row) ;
}

/// @dev Memory layout
/// @dev ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
/// @dev || selector || protected || type || len || x0 || x1 || ... || x_(len-1) ||
/// @dev ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
func _get_row_from_matrix_by_key{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_key: felt, _matrix_len: felt, _matrix: felt*) -> (res_len: felt, res: felt*, flags: Variable) {
    alloc_locals;
    let (local NULLptr: felt*) = alloc();

    // No data in memory
    if (_matrix_len == 0) {
        return (0, NULLptr, Variable(0,0,0,0));
    }
    
    // Variable not in memory
    if (_matrix_len == -1) {
        return (0, NULLptr, Variable(0,0,0,0));
    }

    if (_matrix[0] == _key) {
        let flags = Variable(
                    selector = _key,
                    protected = _matrix[Variable.protected],
                    type = _matrix[Variable.type],
                    data_len = _matrix[Variable.data_len],
                );
        return (_matrix[Variable.SIZE], _matrix + Variable.SIZE, flags);
    }
    let next_row_len = _matrix_len - Variable.SIZE - _matrix[Variable.SIZE];
    let next_row = _matrix + Variable.SIZE + _matrix[Variable.SIZE];

    return _get_row_from_matrix_by_key(_key, next_row_len, next_row) ;
}

// @external
// func __ZKLANG__RETURN{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_selector: felt, _felt_code_len: felt, _felt_code: felt*) {
//     return ();
// }
// 
// @external
// func __ZKLANG__GOTO{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_new_instruction_counter: felt) {
//     // curr_instruction_.write(Instruction(_new_instruction_counter, 0, 0, 0, 0, 0, 0));
//     return ();
// }
// 
// @view
// func __ZKLANG__REVERT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
//     with_attr error_message("__ZKLANG__REVERT") {
//         assert 1 = 0;
//     }
//     return ();
// }
// 
// @external
// func __ZKLANG__EVENT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_key: felt, _val_len: felt, _val: felt*) {
//     __ZKLANG__EMIT.emit(_key, _val_len, _val);
//     return ();
// }
// 
// @external
// func deployFunction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_selector: felt, _program_hash: felt, _repo_address: felt) -> () {
//     // TODO AccessControlled
//     // !!! This is right now a single function max !!!
//     fun_selector_index_.write(0, _selector);
//     fun_selector_program_hash_mapping_.write(_selector, _program_hash);
//     program_hash_repo_address_mapping_.write(_program_hash, _repo_address);
//     return ();
// }
// 
// // TODO Store in diamondCut itself
// @external
// func deleteFunction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
//     // AccessControlled
//     // Set function_table(selector) to 0
//     // Set function_array(selector) to 0
//     return ();
// }
// 
// func _load_selectors{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_ptr: felt*, _i: felt) -> felt {
//     alloc_locals;
//     let (selector) = fun_selector_index_.read(_i);
//     if (selector == 0) {
//         return _i;
//     } else {
//         assert _ptr[0] = selector;
//         return _load_selectors(_ptr + 1, _i + 1);
//     }
// }
// 
// // ===================
// // Mandatory functions
// // ===================
// 
// /// @dev Initialize this facet
// @external
// func __constructor__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
//     return ();
// }
// 
// /// @dev Remove this facet
// @external
// func __destructor__() -> () {
//     return ();
// }
// 
// @view
// @raw_output
// func __API__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (retdata_size: felt, retdata: felt*) {
//     let (func_selectors) = get_label_location(selectors_start);
//     return (retdata_size=5, retdata=cast(func_selectors, felt*));
// 
//     selectors_start:
//     dw API.CORE.__ZKLANG__ADD;
//     dw API.CORE.__ZKLANG__RETURN;
//     dw API.CORE.__ZKLANG__EVENT;
//     dw API.CORE.__ZKLANG__GOTO;
//     dw API.CORE.__ZKLANG__REVERT;
// }
// 
// /// @dev Exported view and invokable functions of this facet
// @view
// @raw_output
// func __get_function_selectors__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (retdata_size: felt, retdata: felt*) {
//     alloc_locals;
//     let (local sel: felt*) = alloc();
//     let sel_len = _load_selectors(sel, 0);
// 
//     let (func_selectors) = get_label_location(selectors_start);
// 
//     let (local res: felt*) = alloc();
//     memcpy(res,cast(func_selectors, felt*), 1);
//     memcpy(res + 1, sel, sel_len);
// 
//     return (retdata_size=sel_len + 1, retdata=res);
// 
//     selectors_start:
//     dw FUNCTION_SELECTORS.ZKLANG.deployFunction;
// }
// 
// /// @dev Define all supported interfaces of this facet
// @view
// func __supports_interface__(_interface_id: felt) -> (res: felt) {
//     // TODO Read from storage var
//     return (res=FALSE);
// }
