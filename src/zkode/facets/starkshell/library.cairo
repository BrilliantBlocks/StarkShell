%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.memcpy import memcpy

from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    library_call,
)

from src.zkode.constants import API
from src.zkode.diamond.IDiamond import IDiamond
from src.zkode.diamond.library import Library
from src.zkode.facets.starkshell.structs import (
    DataTypes,
    Instruction,
    Function,
    Primitive,
    Variable,
)

@storage_var
func fun_selector_index_(i: felt) -> (fun_selector: felt) {
}

@storage_var
func fun_selector_program_hash_mapping_(fun_selector: felt) -> (program_hash: felt) {
}

@storage_var
func program_hash_repo_address_mapping_(program_hash: felt) -> (repo_address: felt) {
}

@storage_var
func fun_selector_params_mapping_(fun_selector: felt) -> (res: felt) {
}

namespace Program {
    func get_instruction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _pc: felt, _program_len: felt, _program: felt*
    ) -> Instruction* {
        if (_pc == 0) {
            let instruction = cast(_program, Instruction*);
            return instruction;
        }

        return get_instruction(
            _pc=_pc - 1,
            _program_len=_program_len - Instruction.SIZE,
            _program=_program + Instruction.SIZE,
        );
    }

    func execute_primitive{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _primitive: Primitive, _calldata_len: felt, _calldata: felt*
    ) -> (res_len: felt, res: felt*) {
        alloc_locals;

        let (res_len, res) = library_call(
            class_hash=_primitive.class_hash,
            function_selector=_primitive.selector,
            calldata_size=_calldata_len,
            calldata=_calldata,
        );

        return (res_len, res);
    }

    func prepare{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _selector: felt, _program_raw_len: felt, _program_raw: felt*
    ) -> (program_len: felt, program: felt*) {
        alloc_locals;
        // validate(_program_raw[0], _program_raw + 1);
        validate(_program_raw_len, _program_raw);

        let (this_diamond) = get_contract_address();
        let (this_zklang) = IDiamond.facetAddress(this_diamond, _selector);

        let (local program: felt*) = alloc();
        let program_len = _program_raw_len;

        replace_zero_class_hashes_with_self(program, this_zklang, _program_raw_len, _program_raw);

        return (program_len, program);
    }

    // TODO Requires another iteration of refactoring
    func validate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _program_len: felt, _program: felt*
    ) -> () {
        alloc_locals;
        // TODO verifiy all class hashes are included as facets
        // TODO verify that facets have primitive

        if (_program_len == 0) {
            return ();
        }
        let instruction = cast(_program, Instruction*);
        with_attr error_message("CORRUPT CODE input1.protected {_program_len}") {
            assert (instruction.input1.protected - 1) * instruction.input1.protected = 0;
        }
        with_attr error_message("CORRUPT CODE input2.protected") {
            assert (instruction.input2.protected - 1) * instruction.input2.protected = 0;
        }
        with_attr error_message("CORRUPT CODE output.protected") {
            assert (instruction.output.protected - 1) * instruction.output.protected = 0;
        }
        with_attr error_message("CORRUPT CODE input1.type") {
            assert (instruction.input1.type - 1) * instruction.input1.type = 0;
        }
        with_attr error_message("CORRUPT CODE input2.type") {
            assert (instruction.input2.type - 1) * instruction.input2.type = 0;
        }
        with_attr error_message("CORRUPT CODE output.type") {
            assert (instruction.output.type - 1) * instruction.output.type = 0;
        }

        return validate(_program_len - Instruction.SIZE, _program + Instruction.SIZE);
    }

    // TODO Requires another iteration of refactoring
    func replace_zero_class_hashes_with_self{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(_program: felt*, _this_zklang: felt, _program_raw_len: felt, _program_raw: felt*) -> () {
        alloc_locals;

        if (_program_raw_len == 0) {
            return ();
        }
        let instruction = cast(_program_raw, Instruction*);
        memcpy(_program, _program_raw, Primitive.class_hash);
        if (instruction.primitive.class_hash == 0) {
            tempvar x = new (_this_zklang);
            memcpy(_program + Primitive.class_hash, x, 1);
        } else {
            memcpy(_program + Primitive.class_hash, _program_raw + Primitive.class_hash, 1);
        }
        memcpy(
            _program + Primitive.class_hash + 1,
            _program_raw + Primitive.class_hash + 1,
            Instruction.SIZE - Primitive.class_hash - 1,
        );

        return replace_zero_class_hashes_with_self(
            _program=_program + Instruction.SIZE,
            _this_zklang=_this_zklang,
            _program_raw_len=_program_raw_len - Instruction.SIZE,
            _program_raw=_program_raw + Instruction.SIZE,
        );
    }
}

// Memory layout
// ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
// || selector || protected || type || data_len || data_0 || data_1 || ... || data_(len-1) ||
// ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
namespace Memory {
    func init{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _memory_len: felt,
        _memory: felt*,
        _calldata_len: felt,
        _calldata: felt*,
        _fun_param_len: felt,
        _fun_param: felt*,
        _root: felt,
    ) -> (mem_len: felt, mem: felt*) {
        alloc_locals;
        let mem_len = 0;
        let (local mem: felt*) = alloc();

        let mem_len = append_calldata_var(mem_len, mem, _calldata_len, _calldata);
        let mem_len = append_caller_address_var(mem_len, mem);
        let mem_len = append_contract_address_var(mem_len, mem);
        let mem_len = append_booleans_var(mem_len, mem);
        let mem_len = append_root_var(mem_len, mem, _root);

        // get_block_number()
        // get_timestampe()

        // TODO what if calldata var already present?
        // Make this update_memory
        memcpy(mem + mem_len, _memory, _memory_len);
        let mem_len = mem_len + _memory_len;

        return (mem_len, mem);
    }

    func append_root_var{syscall_ptr: felt*, range_check_ptr}(
        _ptr_len: felt, _ptr: felt*, _root: felt
    ) -> felt {
        alloc_locals;

        tempvar root_address_var = new Variable(
            selector=API.CORE.__ZKLANG__ROOT_VAR,
            protected=TRUE,
            type=DataTypes.FELT,
            data_len=1,
            );
        memcpy(_ptr + _ptr_len, root_address_var, Variable.SIZE);
        assert _ptr[_ptr_len + Variable.SIZE] = _root;

        return _ptr_len + Variable.SIZE + root_address_var.data_len;
    }

    func append_booleans_var{syscall_ptr: felt*}(_ptr_len: felt, _ptr: felt*) -> felt {
        alloc_locals;

        tempvar false_var = new Variable(
            selector=API.CORE.__ZKLANG__FALSE_VAR,
            protected=TRUE,
            type=DataTypes.BOOL,
            data_len=1,
            );

        tempvar true_var = new Variable(
            selector=API.CORE.__ZKLANG__TRUE_VAR,
            protected=TRUE,
            type=DataTypes.BOOL,
            data_len=1,
            );

        memcpy(_ptr + _ptr_len, false_var, Variable.SIZE);
        assert _ptr[_ptr_len + Variable.SIZE] = FALSE;

        memcpy(_ptr + _ptr_len + Variable.SIZE + false_var.data_len, true_var, Variable.SIZE);
        assert _ptr[_ptr_len + Variable.SIZE + false_var.data_len + Variable.SIZE] = TRUE;

        return _ptr_len + Variable.SIZE + false_var.data_len + Variable.SIZE + true_var.data_len;
    }

    func append_contract_address_var{syscall_ptr: felt*}(_ptr_len: felt, _ptr: felt*) -> felt {
        alloc_locals;

        tempvar contract_address_var = new Variable(
            selector=API.CORE.__ZKLANG__CONTRACT_ADDRESS_VAR,
            protected=TRUE,
            type=DataTypes.FELT,
            data_len=1,
            );
        let (contract_address) = get_contract_address();
        memcpy(_ptr + _ptr_len, contract_address_var, Variable.SIZE);
        assert _ptr[_ptr_len + Variable.SIZE] = contract_address;

        return _ptr_len + Variable.SIZE + contract_address_var.data_len;
    }

    func append_caller_address_var{syscall_ptr: felt*}(_ptr_len: felt, _ptr: felt*) -> felt {
        alloc_locals;

        tempvar caller_address_var = new Variable(
            selector=API.CORE.__ZKLANG__CALLER_ADDRESS_VAR,
            protected=TRUE,
            type=DataTypes.FELT,
            data_len=1,
            );
        let (caller) = get_caller_address();
        memcpy(_ptr + _ptr_len, caller_address_var, Variable.SIZE);
        assert _ptr[_ptr_len + Variable.SIZE] = caller;

        return _ptr_len + Variable.SIZE + caller_address_var.data_len;
    }

    func append_calldata_var(
        _ptr_len: felt, _ptr: felt*, _calldata_len: felt, _calldata: felt*
    ) -> felt {
        tempvar calldata_var = new Variable(
            selector=API.CORE.__ZKLANG__CALLDATA_VAR,
            protected=FALSE,
            type=DataTypes.FELT,
            data_len=_calldata_len,
            );
        memcpy(_ptr + _ptr_len, calldata_var, Variable.SIZE);
        memcpy(_ptr + _ptr_len + Variable.SIZE, _calldata, _calldata_len);

        return _ptr_len + Variable.SIZE + _calldata_len;
    }

    func load_variable_payload{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _selector1: felt, _selector2: felt, _memory_len: felt, _memory: felt*
    ) -> (payload_len: felt, payload: felt*) {
        alloc_locals;

        if (_selector1 == 0 and _selector2 == 0) {
            tempvar NULLvariable = new (0);
            return (1, NULLvariable);
        }

        if (_selector1 == 0) {
            let (var_len, var) = load_variable(_selector2, _memory_len, _memory);

            return (payload_len=var_len - Variable.SIZE + 1, payload=var + Variable.SIZE - 1);
        }

        if (_selector2 == 0) {
            let (var_len, var) = load_variable(_selector1, _memory_len, _memory);

            return (payload_len=var_len - Variable.SIZE + 1, payload=var + Variable.SIZE - 1);
        }

        let (var1_len, var1) = load_variable(_selector1, _memory_len, _memory);
        let (var2_len, var2) = load_variable(_selector2, _memory_len, _memory);

        let (local merged_payload: felt*) = alloc();
        local merged_payload_len = var1[Variable.data_len] + var2[Variable.data_len];

        assert merged_payload[0] = merged_payload_len;
        memcpy(merged_payload + 1, var1 + Variable.SIZE, var1[Variable.data_len]);
        memcpy(
            merged_payload + 1 + var1[Variable.data_len],
            var2 + Variable.SIZE,
            var2[Variable.data_len],
        );

        return (payload_len=merged_payload_len + 1, payload=merged_payload);
    }

    func load_variable{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _var_selector: felt, _memory_len: felt, _memory: felt*
    ) -> (var_len: felt, var: felt*) {
        let (l_len, l, v_len, v, r_len, r) = _split_memory(_var_selector, _memory_len, _memory);
        return (v_len, v);
    }

    func update_variable{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _var_selector: felt, _memory_len: felt, _memory: felt*, _payload_len: felt, _payload: felt*
    ) -> (new_memory_len: felt, new_memory: felt*) {
        alloc_locals;

        if (_var_selector == 0) {
            return (_memory_len, _memory);
        }

        let (l_len, l, v_len, v, r_len, r) = _split_memory(_var_selector, _memory_len, _memory);

        with_attr error_message("CONSTS ARE IMMUTABLE") {
            assert v[Variable.protected] = FALSE;
        }

        let (local new_memory: felt*) = alloc();
        memcpy(new_memory, l, l_len);
        memcpy(new_memory + l_len, v, Variable.SIZE - 1);
        memcpy(new_memory + l_len + Variable.SIZE - 1, new (_payload_len), 1);
        memcpy(new_memory + l_len + Variable.SIZE, _payload, _payload_len);
        memcpy(new_memory + l_len + Variable.SIZE + _payload_len, r, r_len);
        let new_memory_len = l_len + Variable.SIZE + _payload_len + r_len;

        return (new_memory_len, new_memory);
    }

    func _split_memory{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _var_selector: felt, _memory_len: felt, _memory: felt*
    ) -> (
        left_memory_len: felt,
        left_memory: felt*,
        var_len: felt,
        var: felt*,
        right_memory_len: felt,
        right_memory: felt*,
    ) {
        alloc_locals;
        let (local left_memory: felt*) = alloc();
        let (local var: felt*) = alloc();
        let (local right_memory: felt*) = alloc();

        let var_in_memory = is_variable_in_memory(_var_selector, _memory_len, _memory);

        local v_in_memory = var_in_memory;

        if (var_in_memory == TRUE) {
            let (var_start, var_end) = get_index_of_var_in_memory(_var_selector, 0, _memory);
            let var_len = var_end - var_start;

            memcpy(left_memory, _memory, var_start);
            memcpy(var, _memory + var_start, var_len);
            memcpy(right_memory, _memory + var_end, _memory_len - var_end);

            return (var_start, left_memory, var_len, var, _memory_len - var_end, right_memory);
        } else {
            return (0, left_memory, 0, var, 0, right_memory);
        }
    }

    func is_variable_in_memory{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _selector: felt, _memory_len: felt, _memory: felt*
    ) -> felt {
        alloc_locals;

        if (_memory_len == 0) {
            return FALSE;
        }

        if (_memory_len == -1) {
            return FALSE;
        }

        if (_memory[Variable.selector] == _selector) {
            return TRUE;
        }

        local total_var_size = Variable.SIZE + _memory[Variable.data_len];
        local remaining_memory_len: felt = _memory_len - total_var_size;
        local remaining_memory: felt* = _memory + total_var_size;
        local v_selector = _memory[Variable.selector];
        local v_protected = _memory[Variable.protected];
        local v_type = _memory[Variable.type];
        local v_data_len = _memory[Variable.data_len];

        with_attr error_message(
                "BREAKPOINT is_variable_in_memory() recursion {v_selector} {v_protected} {v_type} {v_data_len} {_memory_len} {remaining_memory_len}") {
            return is_variable_in_memory(
                _selector=_selector, _memory_len=remaining_memory_len, _memory=remaining_memory
            );
        }
    }

    // / @dev Assume variable to be in memory
    func get_index_of_var_in_memory{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(_selector: felt, _i: felt, _memory: felt*) -> (start: felt, end: felt) {
        let total_var_size = Variable.SIZE + _memory[Variable.data_len];

        if (_memory[Variable.selector] == _selector) {
            return (start=_i, end=_i + total_var_size,);
        }

        return get_index_of_var_in_memory(
            _selector=_selector, _i=_i + total_var_size, _memory=_memory + total_var_size
        );
    }

    func push(_data_len: felt, _data: felt*) -> (data_len: felt, data: felt*) {
        alloc_locals;
        let (local data: felt*) = alloc();

        assert data[0] = _data_len;
        memcpy(data + 1, _data, _data_len);

        return (data_len=_data_len + 1, data=data);
    }

    func pop(_data_len: felt, _data: felt*) -> (data_len: felt, data: felt*) {
        alloc_locals;
        let (local data: felt*) = alloc();

        memcpy(data, _data + 1, _data_len - 1);

        return (data_len=_data_len - 1, data=data);
    }
}

namespace State {
    func assert_not_existing_fun{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _function: Function
    ) {
        let (selector) = fun_selector_program_hash_mapping_.read(_function.selector);
        with_attr error_message("FUNCTION EXISTS") {
            assert selector = 0;
        }

        return ();
    }

    func get_fun{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _selector: felt
    ) -> Function {
        let (program_hash) = fun_selector_program_hash_mapping_.read(_selector);
        let (repo_address) = program_hash_repo_address_mapping_.read(program_hash);
        let fun = Function(_selector, program_hash, repo_address);

        return fun;
    }

    func set_fun{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _function: Function, _params_len: felt, _params: felt*
    ) -> () {
        alloc_locals;
        let first_free_index = first_free_fun_index(_function.selector, 0);
        fun_selector_index_.write(first_free_index, _function.selector);
        fun_selector_program_hash_mapping_.write(_function.selector, _function.program_hash);
        program_hash_repo_address_mapping_.write(_function.program_hash, _function.repo_address);

        // Make likelihood of storage collisions neglible even in the case of corrupt selectors
        let (offset: felt) = hash2{hash_ptr=pedersen_ptr}(_function.selector, 0);
        fun_selector_params_mapping_.write(offset, _params_len);
        set_params_recursively(offset, _params_len, _params);

        return ();
    }

    func set_params_recursively{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _selector: felt, _params_len: felt, _params: felt*
    ) -> () {
        alloc_locals;

        if (_params_len == 0) {
            return ();
        }

        local last_element = _params[_params_len - 1];
        fun_selector_params_mapping_.write(_selector + _params_len, last_element);

        return set_params_recursively(_selector, _params_len - 1, _params);
    }

    func get_params{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _selector: felt
    ) -> (res_len: felt, res: felt*) {
        alloc_locals;

        local params_len = 0;
        let (local params: felt*) = alloc();
        let (offset: felt) = hash2{hash_ptr=pedersen_ptr}(_selector, 0);

        let params_len = populate_params(offset, params_len, params);

        return (params_len, params);
    }

    func populate_params{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _selector: felt, _params_len: felt, _params: felt*
    ) -> felt {
        alloc_locals;

        let (params_len: felt) = fun_selector_params_mapping_.read(_selector);
        if (_params_len == params_len) {
            return _params_len;
        }

        let (data_point: felt) = fun_selector_params_mapping_.read(_selector + _params_len + 1);
        assert _params[_params_len] = data_point;

        return populate_params(_selector, _params_len + 1, _params + 1);
    }

    func first_free_fun_index{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _selector: felt, _i: felt
    ) -> felt {
        let (fun_selector) = fun_selector_index_.read(_i);
        if (fun_selector == _selector) {
            return _i;
        }
        if (fun_selector == 0) {
            return _i;
        }

        return first_free_fun_index(_selector, _i + 1);
    }

    func load_selectors{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _ptr: felt*, _i: felt
    ) -> felt {
        alloc_locals;

        let (selector) = fun_selector_index_.read(_i);
        if (selector == 0) {
            return _i;
        } else {
            let (program_hash) = fun_selector_program_hash_mapping_.read(selector);
            if (program_hash == 0) {
                // if program_hash mapping is zero
                // Function was removed
            } else {
                assert _ptr[0] = selector;
            }

            return load_selectors(_ptr + 1, _i + 1);
        }
    }
}
