%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.registers import get_label_location

from src.constants import FUNCTION_SELECTORS


struct REGISTERS {
    PC: felt,
    FC: felt,
}

@event
func __ZKLANG__EMIT(_key: felt, _val_len: felt, _val: felt*){
}

/// @notice garbage collect values after exec
@storage_var
func register_(reg: felt) -> (val: felt) {
}

/// @notice persistent || immutable
/// TODO BFR registry, whole interfaces can be ported
/// Gives the deployed facet an interfaceID
/// And this BFR registry holds/stores all programs
@storage_var
func function_table_(selector: felt) -> (program_hash: felt) {
}

/// @notice persistent || immutable
/// TODO global program store
@storage_var
func program_store_(hash: felt) -> (program_start: felt) {
}

/// @notice garbage collect values after exec
@storage_var
func temporary_variables_(index: felt) -> (var_selector: felt) {
}

/// @notice garbage collect values after exec
@storage_var
func temporary_variable_table_(var_selector: felt) -> (var_start: felt) {
}

/// @notice garbage collect values after exec
@storage_var
func persistent_variable_table_(var_selector: felt) -> (var_start: felt) {
}

// TODO Log variables as emitted events
// TODO Whitelist storage_var access
@external
func __default__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_selector: felt, _calldata_len: felt, _calldata: felt*) -> () {
    // store calldata as input on tape      // BFR.zklang.set_input()
    zklang_exec(_program=_selector, _pc=0);  // BFR.zklang.exec(program, pc)
    // garbage_collect                      // BFR.zklang.clean()
    // read output tape                     // BFR.zklang.getOutput()
    // return output tape
    return ();
}

@external
func zklang_exec{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_program: felt, _pc: felt) -> () {
    // load next instruction (_program_selector, pc)
    // if __ZKLANG__RETURN read output var and return
    // library call to BFR
    return ();
}

@external
func __ZKLANG__SET_VAR{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_selector: felt, _felt_code_len: felt, _felt_code: felt*) -> () {
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
func __ZKLANG__GOTO{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_pc: felt) -> () {
    register_.write(REGISTERS.PC, _pc);
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
func deployFunction{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_selector: felt, _felt_code_len: felt, _felt_code: felt*) -> () {
    // AccessControlled
    // Compute hash of felt code
    // Store in program store
    // Map selector to program hash
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

func _process{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (){
    // streams - exec next line in program table
    return ();
}

func _garbage_collect{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (){
    // streams -  for each temp var in array, set to 0
    // set pc and fc, return to zero
    return ();
}

func _set_temporary_variable_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_var_sel: felt, _var_len: felt, _var: felt*) -> () {
    // streams - write to first zero in var array
    temporary_variable_table_.write(_var_sel, _var_len);
    // streams - append data
    return ();
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

/// @dev Exported view and invokable functions of this facet
@view
@raw_output
func __get_function_selectors__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (retdata_size: felt, retdata: felt*) {
    // read deployed func selectors
    let (func_selectors) = get_label_location(selectors_start);
    return (retdata_size=2, retdata=cast(func_selectors, felt*));
    // TODO dynamically include functions from func_array

    selectors_start:
    dw FUNCTION_SELECTORS.ZKLANG.deployFunction;
    dw FUNCTION_SELECTORS.ZKLANG.deleteFunction;
}

/// @dev Define all supported interfaces of this facet
@view
func __supports_interface__(_interface_id: felt) -> (res: felt) {
    // TODO Read from storage var
    return (res=FALSE);
}
