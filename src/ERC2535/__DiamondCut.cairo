%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location

from src.constants import FUNCTION_SELECTORS, IDIAMONDCUT_ID

/// @dev Initialize this facet
@external
func __constructor__() -> () {
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
func __get_function_selectors__() -> (retdata_size: felt, retdata: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (retdata_size=3, retdata=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.DIAMONDCUT.diamondCut;
    dw FUNCTION_SELECTORS.DIAMONDCUT.setAlias;
    dw FUNCTION_SELECTORS.DIAMONDCUT.setFunctionFee;
}

/// @dev Define all supported interfaces of this facet
@view
func __supports_interface__(_interface_id: felt) -> (res: felt) {
    if (_interface_id == IDIAMONDCUT_ID) {
        return (res=TRUE);
    }
    return (res=FALSE);
}
