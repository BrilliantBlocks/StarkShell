%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.registers import get_label_location

from src.constants import FUNCTION_SELECTORS, IERC5185_ID


@event
func MetadataUpdates(token_uri: felt) {
}

@event
func ChangeEvents(property: felt, action: felt, value: felt) {
}


@external
func updateMetadata{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_uri: felt, property: felt, action: felt, value: felt
) -> () {
    
	MetadataUpdates.emit(token_uri);
	ChangeEvents.emit(property, action, value);

    return ();
}


@external
func __init_facet__{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> () {

    return ();
}


@view
func __get_function_selectors__() -> (res_len: felt, res: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (res_len=1, res=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.ERC5185.updateMetadata;
}


// @dev Support ERC-165
// @param interface_id
// @return success (0 or 1)
@view
func __supports_interface__(_interface_id: felt) -> (success: felt) {
    if (_interface_id == IERC5185_ID) {
        return (TRUE,);
    }

    return (FALSE,);
}