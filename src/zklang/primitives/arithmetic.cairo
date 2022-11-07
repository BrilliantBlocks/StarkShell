%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.registers import get_label_location

from src.constants import FUNCTION_SELECTORS

@view
func __ZKLANG__ARITHMETIC__ADD(x: felt, y: felt) -> (res: felt) {
    return (res=x + y);
}

@view
func __ZKLANG__ARITHMETIC__SUB(x: felt, y: felt) -> (res: felt) {
    return (res=x - y);
}

// =================
// ZKlang primitives
// =================
@view
@raw_output
func __zklang__() -> (retdata_size: felt, retdata: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (retdata_size=2, retdata=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.ZKLANG.__ZKLANG__ARITHMETIC__ADD;
    dw FUNCTION_SELECTORS.ZKLANG.__ZKLANG__ARITHMETIC__SUB;
}

// ===================
// Mandatory functions
// ===================

// / @dev Initialize this facet
@external
func __constructor__() -> () {
    return ();
}

// / @dev Remove this facet
@external
func __destructor__() -> () {
    return ();
}

// / @dev Exported view and invokable functions of this facet
@view
@raw_output
func __get_function_selectors__() -> (retdata_size: felt, retdata: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (retdata_size=0, retdata=cast(func_selectors, felt*));

    selectors_start:
}

// / @dev Define all supported interfaces of this facet
@view
func __supports_interface__(_interface_id: felt) -> (res: felt) {
    return (res=FALSE);
}
