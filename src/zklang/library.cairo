%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.memcpy import memcpy

from starkware.starknet.common.syscalls import get_contract_address, library_call

from src.constants import API
from src.ERC2535.IDiamond import IDiamond
from src.ERC2535.library import Library


struct Primitive {
    class_hash: felt,
    selector: felt,
}

struct Function {
    selector: felt,
    program_hash: felt,
    repo_address: felt,
}

struct Variable {
    selector: felt,
    protected: felt,
    type: felt,
    data_len:felt,
}

struct Instruction {
    primitive: Primitive,
    input: Variable,
    output: Variable,
}

struct DataTypes {
    FELT: felt,
    BOOL: felt,
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

namespace Program {
    func get_instruction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_pc: felt, _program_len: felt, _program: felt*) -> Instruction* {
        if (_pc == 0) {
            let instruction = cast(_program, Instruction*);
            return instruction;
        }

        return get_instruction(
            _pc = _pc - 1,
            _program_len = _program_len - Instruction.SIZE,
            _program = _program + Instruction.SIZE,
        );
    }

    func execute_primitive{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(_primitive: Primitive, _calldata_len: felt, _calldata: felt*) -> (res_len: felt, res: felt*) {
        let (res_len, res) = library_call(
            class_hash = _primitive.class_hash,
            function_selector = _primitive.selector,
            calldata_size = _calldata_len,
            calldata = _calldata,
        );

        return (res_len, res);
    }

    func prepare{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(_selector: felt, _program_raw_len: felt, _program_raw: felt*) -> (program_len: felt, program: felt*) {
        alloc_locals;
        validate(_program_raw_len, _program_raw);

        let (this_diamond) = get_contract_address();
        let (this_zklang) = IDiamond.facetAddress(this_diamond, _selector);

        let (local program: felt*) = alloc();
        let program_len = _program_raw_len;
        replace_zero_class_hashes_with_self(program, this_zklang, _program_raw_len, _program_raw);

        return (program_len, program);
    }

    func validate{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(_program_len: felt, _program: felt*) -> () {
        alloc_locals;

        if (_program_len == 0) {
            return ();
        }
        let instruction = cast(_program, Instruction*);
        with_attr error_message("CORRUPT CODE") {
            assert (instruction.input.protected - 1) * instruction.input.protected = 0;
            assert (instruction.output.protected - 1) * instruction.output.protected = 0;
            assert (instruction.input.type - 1) * instruction.input.type = 0;
            assert (instruction.output.type - 1) * instruction.output.type = 0;
        }

        return validate(_program_len - Instruction.SIZE, _program + Instruction.SIZE);
    }

    func replace_zero_class_hashes_with_self{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(_program: felt*, _this_zklang: felt, _program_raw_len: felt, _program_raw: felt*) -> () {
        alloc_locals;

        if (_program_raw_len == 0) {
            return ();
        }
        let instruction = cast(_program_raw, Instruction*);
        if (instruction.primitive.class_hash == 0) {
            assert _program[Primitive.class_hash] = _this_zklang;
        } else {
            assert _program[Primitive.selector] = _program_raw[Primitive.selector];
        }
        memcpy(_program, _program_raw, Primitive.selector - 1);
        memcpy(_program + Primitive.SIZE, _program_raw + Primitive.SIZE, _program_raw_len - Primitive.SIZE);

        return replace_zero_class_hashes_with_self(
            _program = _program + Instruction.SIZE,
            _program_raw_len = _program_raw_len - 1,
            _program_raw = _program_raw + Instruction.SIZE,
            _this_zklang = _this_zklang,
        );
    }
}

// Memory layout
// ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// || selector || protected || type || data_len || data_0 || data_1 || ... || data_(len-1) ||
// ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
namespace Memory {
    func init{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_calldata_len: felt, _calldata: felt*) -> (memory_len: felt, memory: felt*) {
        alloc_locals;

        let (local memory: felt*) = alloc();
        let memory_len = Variable.SIZE + _calldata_len;
        tempvar var_metadata = new Variable(
            selector = API.CORE.__ZKLANG__CALLDATA_VAR,
            protected = FALSE,
            type = DataTypes.FELT,
            data_len = _calldata_len,
        );
        memcpy(memory, var_metadata, Variable.SIZE);
        memcpy(memory + Variable.SIZE, _calldata, _calldata_len);

        return (memory_len, memory);
    }

    func load_variable_payload{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _var: Variable, _memory_len: felt, _memory: felt*
        ) -> (var_len: felt, var: felt*) {
        alloc_locals; // TODOO required?
        let (v_len, v) = load_variable(_var.selector, _memory_len, _memory);
        let payload = v + Variable.SIZE;
        let payload_len = v_len - Variable.SIZE;
        return (payload_len, payload);
    }

    func load_variable{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _var_selector: felt, _memory_len: felt, _memory: felt*
        ) -> (var_len: felt, var: felt*) {
        let (l_len, l, v_len, v, r_len, r) = _split_memory(_var_selector, _memory_len, _memory);
        return (v_len, v);
    }

    func update_variable{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(_var: Variable, _memory_len: felt, _memory: felt*, _payload_len: felt, _payload: felt*) -> (new_memory_len: felt, new_memory: felt*) {
        alloc_locals;

        let (l_len, l, v_len, v, r_len, r) = _split_memory(_var.selector, _memory_len, _memory);

        with_attr error_message("CONSTS ARE IMMUTABLE") {
            assert v[Variable.protected] = FALSE;
        }

        let (local new_memory: felt*) = alloc();
        memcpy(new_memory, l, l_len);
        memcpy(new_memory + l_len, v, Variable.SIZE);
        memcpy(new_memory + l_len + Variable.SIZE, _payload, _payload_len);
        memcpy(new_memory + l_len + Variable.SIZE + _payload_len, r, r_len);
        let new_memory_len = l_len + Variable.SIZE + _payload_len + r_len;

        return (new_memory_len, new_memory);
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
}

namespace State {
    func assert_not_existing_fun{
            syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
        }(_function: Function) {
        let (selector) = fun_selector_program_hash_mapping_.read(_function.selector);
        with_attr error_message("FUNCTION EXISTS") {
            assert selector = 0;
        }
        return ();
    }
    
    func get_fun{
            syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
        }(_selector: felt) -> Function {
        let (program_hash) = fun_selector_program_hash_mapping_.read(_selector);
        let (repo_address) = program_hash_repo_address_mapping_.read(program_hash);
        let fun = Function(_selector, program_hash, repo_address);
        return fun;
    }
    
    func set_fun{
            syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
        }(_function: Function) -> () {
        let first_free_index = first_free_fun_index(_function.selector, 0);
        fun_selector_index_.write(first_free_index, _function.selector);
        fun_selector_program_hash_mapping_.write(_function.selector, _function.program_hash);
        program_hash_repo_address_mapping_.write(_function.program_hash, _function.repo_address);
        return ();
    }
    
    func first_free_fun_index{
            syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
        }(_selector: felt, _i: felt) -> felt {
        let (fun_selector) = fun_selector_index_.read(_i);
        if (fun_selector == _selector) {
            return _i;
        }
        if (fun_selector == 0) {
            return _i;
        }
        return first_free_fun_index(_selector, _i + 1);
    }
    
    func load_selectors{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_ptr: felt*, _i: felt) -> felt {
        alloc_locals;
        let (selector) = fun_selector_index_.read(_i);
        if (selector == 0) {
            return _i;
        } else {
            // if program_hash mapping is zero
            let (program_hash) = fun_selector_program_hash_mapping_.read(selector);
            if (program_hash == 0) {
                // Function was removed
            } else {
                assert _ptr[0] = selector;
            }
            return load_selectors(_ptr + 1, _i + 1);
        }
    }
}
