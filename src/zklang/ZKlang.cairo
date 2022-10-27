%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.registers import get_label_location
from starkware.starknet.common.syscalls import get_contract_address, library_call

from onlydust.stream.default_implementation import stream

from src.constants import API, FUNCTION_SELECTORS
from src.ERC2535.IDiamond import IDiamond
from src.Storage.IFlobDB import IFlobDB


struct Function {
    selector: felt,
    program_hash: felt,
    repository_address: felt,
}

@event
func __ZKLANG__EMIT(_key: felt, _val_len: felt, _val: felt*){
}

// program hash, counter, 
/// @notice Garbage collect
@storage_var
func instruction_counter_() -> (res: felt) {
}

/// @dev Store input indexed
/// @notice Garbage collect
@storage_var
func inptape_(i: felt) -> (res: felt) {
}

/// @dev Store output indexed
/// @notice Garbage collect
@storage_var
func outtape_(i: felt) -> (res: felt) {
}

/// @dev Temporary variable store
/// @notice Enumerable
/// @notice Garbage collect
@storage_var
func temptape_(i: felt) -> (res: felt) {
}

/// @dev This is a @storage_var for zklang functions
/// @notice Not enumerable
@storage_var
func perstape_(i: felt) -> (res: felt) {
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

@external
@raw_input
func __default__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(selector: felt, calldata_size: felt, calldata: felt*) -> (res_len: felt, res: felt*) {
    alloc_locals;
    // Prepare execution
    inptape_.write(0, calldata_size);
    stream.foreach(_writeInputOnTape, calldata_size, calldata);

    let (program_hash) = fun_selector_program_hash_mapping_.read(selector);
    let (repo_address) = program_hash_repo_address_mapping_.read(program_hash);
    let (program_len, program) = IFlobDB.load(repo_address, program_hash);

    // Execute
    // instruction_counter_.write(1);
    exec_loop(selector, program_len, program);

    // Temporarily store output
    let (local res: felt*) = alloc();
    let res_len =_readOutputFromTape(res, 0);   // how return single felt?

    // Collect garbage
    let (local temps: felt*) = alloc();
    let temps_len = _readTempsFromTape(res, 0);
    stream.foreach(_resetTempsOnTape, temps_len, temps);
    stream.foreach(_resetInputOnTape, calldata_size, calldata);
    stream.foreach(_resetOutputOnTape, res_len, res);

    // Return output
    return (res_len, res);
}

func _readOutputFromTape{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_ptr: felt*, _ptr_len: felt) -> felt {
    let (total_len) = outtape_.read(0);
    if (_ptr_len == total_len) {
        return _ptr_len;
    }
    let (data) = outtape_.read(_ptr_len + 1);
    assert _ptr[0] = data;
    return _readOutputFromTape(_ptr + 1, _ptr_len + 1);
}

func _writeOutputOnTape{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(index: felt, element: felt*) {
    outtape_.write(index + 1, element[0]);
    return ();
}

func _writeInputOnTape{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(index: felt, element: felt*) {
    inptape_.write(index + 1, element[0]);
    return ();
}

func _readInputFromTape{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_ptr: felt*, _ptr_len: felt) -> felt {
    let (total_len) = inptape_.read(0);
    if (_ptr_len == total_len) {
        return _ptr_len;
    }
    let (data) = inptape_.read(_ptr_len + 1);
    assert _ptr[0] = data;
    return _readInputFromTape(_ptr + 1, _ptr_len + 1);
}

func _resetInputOnTape{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(index: felt, element: felt*) {
    inptape_.write(index + 1, 0);
    if (index == 0) {
        inptape_.write(index, 0);
    }
    return ();
}

func _resetOutputOnTape{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(index: felt, element: felt*) {
    outtape_.write(index + 1, 0);
    if (index == 0) {
        outtape_.write(index, 0);
    }
    return ();
}

func _writeTempOnTape{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(index: felt, element: felt*) {
    temptape_.write(index + 1, element[0]);
    return ();
}

func _readTempsFromTape{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_ptr: felt*, _ptr_len: felt) -> felt {
    let (total_len) = temptape_.read(0);
    if (_ptr_len == total_len) {
        return _ptr_len;
    }
    let (data) = temptape_.read(_ptr_len + 1);
    assert _ptr[0] = data;
    return _readTempsFromTape(_ptr + 1, _ptr_len + 1);
}

func _resetTempsOnTape{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(index: felt, element: felt*) {
    if (index == 0) {
        temptape_.write(index, 0);
        return ();
    }
    let (temp_start) = temptape_.read(index);
    let (temp_len) = temptape_.read(temp_start);
    _resetSingleTempOnTape(temp_start, temp_len);
    return ();
}

func _resetSingleTempOnTape{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_temp_start: felt, _temp_len: felt) {
    temptape_.write(_temp_start + _temp_len, 0);
    if (_temp_len == 0) {
        return ();
    }
    return _resetSingleTempOnTape(_temp_start, _temp_len - 1);
}

func exec_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_selector: felt, _program_len: felt, _program: felt*) -> () {
    alloc_locals;
    let (pc) = instruction_counter_.read();
    if (pc ==  -1) {
        return ();
    }
    let (instruction_len, instruction) = _filter_instruction(pc, _program_len, _program);
    with_attr error_message("FORMAT ERROR") {
        assert instruction_len = 6;
    }

    local library_hash;
    if (instruction[2] == 0) {
        let (this_diamond) = get_contract_address();
        let (this_zklang) = IDiamond.facetAddress(this_diamond, _selector);
        assert library_hash = this_zklang;
        tempvar range_check_ptr = range_check_ptr;
        tempvar syscall_ptr = syscall_ptr;
    } else {
        assert library_hash = instruction[2];
        tempvar range_check_ptr = range_check_ptr;
        tempvar syscall_ptr = syscall_ptr;
    }

    // load calldata
    let (local calldata: felt*) = alloc();
    local calldata_len: felt;
    if (instruction[4] == 0) {
        let calldata_len = _readTempsFromTape(calldata, 0);
        tempvar range_check_ptr = range_check_ptr;
        tempvar syscall_ptr = syscall_ptr;
    } else {
        with_attr error_message("WRONG FORMAT") {
            assert instruction[4] = 1;
        }
        let calldata_len = _readInputFromTape(calldata, 0);
        tempvar range_check_ptr = range_check_ptr;
        tempvar syscall_ptr = syscall_ptr;
    }

    // Execute primitive
    let (res_len, res) = library_call(
        class_hash=library_hash,
        function_selector=instruction[3],
        calldata_size=calldata_len,
        calldata=calldata,
    );

    // TODO store in instrution[0], instruction[1]
    if (instruction[4] == 0) {
        // TODO discard on instruction[1] == 0
        _writeTempsOnTape(instruction[1], res_len, res);
    } else {
        _writeOutputOnTape(0, res_len, res);
    }

    return exec_loop(_selector, _program_len, _program);
}

func _filter_instruction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_i: felt, _program_len: felt, _program: felt*) -> (res_len: felt, res: felt*) {
    alloc_locals;
    if (_i == 0) {
        return (_program[0], _program + 1);
    }
    return _filter_instruction(_i - 1, _program_len - _program[0] - 1, _program + _program[0] + 1);
}

//func __ZKLANG__SET_VAR{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_selector: felt, _felt_code_len: felt, _felt_code: felt*) -> () {
@external
func __ZKLANG__SET_VAR{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_selector: felt) -> () {
    with_attr error_message("BREAKPOINT") {
        assert 1 = 0;
    }

    // temptape_.write(_selector, _felt_code_len);
    // stream.foreach(_writeTempOnTape, _felt_code_len, _felt_code);
    return ();
}

@external
func __ZKLANG__RETURN{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_selector: felt, _felt_code_len: felt, _felt_code: felt*) -> () {
    instruction_counter_.write(-2);
    return ();
}

@view
func __ZKLANG__GET_VAR{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_selector: felt, _felt_code_len: felt, _felt_code: felt*) -> () {
    return ();
}

@external
func __ZKLANG__SET_STATE{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_selector: felt, _felt_code_len: felt, _felt_code: felt*) -> () {
    return ();
}

@view
func __ZKLANG__GET_STATE{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_selector: felt, _felt_code_len: felt, _felt_code: felt*) -> () {
    return ();
}

@external
func __ZKLANG__GOTO{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_new_instruction_counter: felt) -> () {
    instruction_counter_.write(_new_instruction_counter);
    return ();
}

@view
func __ZKLANG__REVERT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    with_attr error_message("__ZKLANG__REVERT") {
        assert 1 = 0;
    }
    return ();
}

@external
func __ZKLANG__EVENT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_key: felt, _val_len: felt, _val: felt*) -> () {
    __ZKLANG__EMIT.emit(_key, _val_len, _val);
    return ();
}

// TODO Store in diamondCut itself
@external
func deployFunction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_selector: felt, _program_hash: felt, _repo_address: felt) -> () {
    // TODO AccessControlled
    // !!! This is right now a single function max !!!
    fun_selector_index_.write(0, _selector);
    fun_selector_program_hash_mapping_.write(_selector, _program_hash);
    program_hash_repo_address_mapping_.write(_program_hash, _repo_address);
    return ();
}

// TODO Store in diamondCut itself
@external
func deleteFunction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    // AccessControlled
    // Set function_table(selector) to 0
    // Set function_array(selector) to 0
    return ();
}

func _load_selectors{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_ptr: felt*, _i: felt) -> felt {
    alloc_locals;
    let (selector) = fun_selector_index_.read(_i);
    if (selector == 0) {
        return _i;
    } else {
        assert _ptr[0] = selector;
        return _load_selectors(_ptr + 1, _i + 1);
    }
}

// ===================
// Mandatory functions
// ===================

/// @dev Initialize this facet
@external
func __constructor__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    return ();
}

/// @dev Remove this facet
@external
func __destructor__() -> () {
    return ();
}

@view
@raw_output
func __API__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (retdata_size: felt, retdata: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (retdata_size=3, retdata=cast(func_selectors, felt*));

    selectors_start:
    dw API.CORE.__ZKLANG__ADD;
    dw API.CORE.__ZKLANG__RETURN;
    dw API.CORE.__ZKLANG__SET_VAR;
}

/// @dev Exported view and invokable functions of this facet
@view
@raw_output
func __get_function_selectors__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (retdata_size: felt, retdata: felt*) {
    alloc_locals;
    let (local sel: felt*) = alloc();
    let sel_len = _load_selectors(sel, 0);

    let (func_selectors) = get_label_location(selectors_start);

    let (local res: felt*) = alloc();
    memcpy(res,cast(func_selectors, felt*), 1);
    memcpy(res + 1, sel, sel_len);

    return (retdata_size=sel_len + 1, retdata=res);

    selectors_start:
    dw FUNCTION_SELECTORS.ZKLANG.deployFunction;
}

/// @dev Define all supported interfaces of this facet
@view
func __supports_interface__(_interface_id: felt) -> (res: felt) {
    // TODO Read from storage var
    return (res=FALSE);
}
