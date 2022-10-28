%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.registers import get_label_location
from starkware.starknet.common.syscalls import get_contract_address, library_call

from onlydust.stream.default_implementation import stream

from src.constants import API, FUNCTION_SELECTORS
from src.ERC2535.IDiamond import IDiamond
from src.Storage.IFlobDB import IFlobDB


struct Instruction {
    facet_class_hash: felt,
    primitive_selector: felt,
    var_in_selector: felt,
    var_out_selector: felt,
}

struct VariableFlags {
    selector: felt,
    protected: felt,
    type: felt,
}

struct VariableType {
    FELT: felt,
    BOOL: felt,
}

@event
func __ZKLANG__EMIT(_key: felt, _val_len: felt, _val: felt*){
}

@storage_var
func __ZKLANG__storage_(i: felt) -> (val: felt) {
}

@storage_var
func fun_selector_index_(i: felt) -> (fun_selector: felt) {
}

@storage_var
func fun_selector_program_hash_mapping_(selector: felt) -> (program_hash: felt) {
}

@storage_var
func program_hash_repo_address_mapping_(program_hash: felt) -> (repo_address: felt) {
}

// @external
// @raw_input
// @raw_output
// func __default__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(selector: felt, calldata_size: felt, calldata: felt*) -> (retdata_size: felt, retdata: felt*) {
//     alloc_locals;
//     // Prepare
//     let (program_hash) = fun_selector_program_hash_mapping_.read(selector);
//     let (repo_address) = program_hash_repo_address_mapping_.read(program_hash);
//     let (program_len, program) = IFlobDB.load(repo_address, program_hash);
// 
//     let (this_diamond) = get_contract_address();
//     let (this_zklang) = IDiamond.facetAddress(this_diamond, _selector);
// 
//     // load calldata into memory
// 
//     // Execute
//     let (retdata_size, retdata) = exec_loop(
//         0,
//         FALSE,
//         selector,
//         program_len,
//         program,
//         calldata_size,
//         calldata,
//         this_zklang,
//     );
// 
//     return (retdata_size, retdata);
// }

// func exec_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//         _pc: felt,
//         _halt: felt,
//         _selector: felt,
//         _program_len: felt,
//         _program: felt*,
//         _calldata_len: felt,
//         _calldata: felt*,
//         _storage: felt*,
//         _this_zklang: felt,
//     ) -> (res_len: felt, res: felt*) {
//     alloc_locals;
// 
//     // Filter current instruction from program
//     let (instruction_code_len, instruction_code) = _get_row_from_matrix_by_index(
//                                             _n = _pc,
//                                             _matrix_len = _program_len,
//                                             _matrix = _program,
//                                          );
// 
//     with_attr error_message("FORMAT ERROR") {
//         assert instruction_code_len = Instruction.SIZE;
//     }
// 
//     let curr_instruction = cast(instruction_code, Instruction*);
// 
//     // Facet hash of requested primitive
//     let is_zero = is_zero(curr_instruction.class_hash);
//     let facet_hash = _if_x_eq_true_return_y_else_z(is_zero, this_zklang, curr_instruction.class_hash);
// 
//     // Get variable from memory
//     let (var_len, var, flags) = _get_row_from_matrix_by_key(curr_instruction.var_keyword, _memory_len, _memory);
// 
//     // Execute primitive
//     let (res_len, res) = library_call(
//         class_hash=facet_hash,
//         function_selector=curr_instruction.selector,
//         calldata_size=var_len,
//         calldata=var,
//     );
// 
//     // Update memory
//     _cut_row_from_matrix_by_key(curr_instruction.var_keyword, _memory_len, _memory);
//     let (local new_memory: felt*) = alloc();
//     let new_memory_len = _append_row_to_matrix();
// 
//     // Stop exec_loop check return temp variable, and reset
// 
//     return exec_loop(
//         _instruction_count + 1,  // TODO GOTO variable, if goto is read, reset
//         _selector,
//         _program_len,
//         _program
//     );
// }

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

func _update_memory_matrix{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_var_len: felt, _var: felt*, _flags: VariableFlags) -> (res_len: felt, res: felt*) {
    alloc_locals;
    // split_memory()
    // if exists
    // assert not write protected
    // assert type
    // concatenate_memory()
    return ();
}

/// @dev Memory layout
/// @dev ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
/// @dev || selector || protected || type || len || x0 || x1 || ... || x_(len-1) ||
/// @dev ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
func _get_row_from_matrix_by_key{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_key: felt, _matrix_len: felt, _matrix: felt*) -> (res_len: felt, res: felt*, flags: VariableFlags) {
    alloc_locals;
    let (local NULLptr: felt*) = alloc();

    // No data in memory
    if (_matrix_len == 0) {
        return (0, NULLptr, VariableFlags(0,0,0));
    }
    
    // Variable not in memory
    if (_matrix_len == -1) {
        return (0, NULLptr, VariableFlags(0,0,0));
    }

    if (_matrix[0] == _key) {
        let flags = VariableFlags(
                    selector = _key,
                    protected = _matrix[VariableFlags.protected],
                    type = _matrix[VariableFlags.type],
                );
        return (_matrix[VariableFlags.SIZE], _matrix + VariableFlags.SIZE + 1, flags);
    }
    let next_row_len = _matrix_len - VariableFlags.SIZE - _matrix[VariableFlags.SIZE] - 1;
    let next_row = _matrix + VariableFlags.SIZE + _matrix[VariableFlags.SIZE] + 1;

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
