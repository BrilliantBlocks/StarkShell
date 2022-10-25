%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.registers import get_label_location

from src.constants import FUNCTION_SELECTORS


struct REGISTERS {
    PC: felt,
    FC: felt,
}

/// @notice garbage collect values after exec
@storage_var
func register(reg: felt) -> (val: felt) {
}

/// @notice persistent || immutable
@storage_var
func function_table(selector: felt) -> (program_hash: felt) {
}

/// @notice persistent || immutable
/// TODO global program store
@storage_var
func program_store(hash: felt) -> (program_start: felt) {
}

/// @notice garbage collect values after exec
@storage_var
func temporary_variables(index: felt) -> (var_selector: felt) {
}

/// @notice garbage collect values after exec
@storage_var
func temporary_variable_table(var_selector: felt) -> (var_start: felt) {
}

/// @notice garbage collect values after exec
@storage_var
func persistent_variable_table(var_selector: felt) -> (var_start: felt) {
}

// TODO Log variables as emitted events
// TODO Whitelist storage_var access

@external
func __default__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    with_attr error_message("FALLBACK IN CLASS IS WORKING") {
        assert 1 = 0;
    }
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
