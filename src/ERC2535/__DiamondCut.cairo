%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location

from src.constants import FUNCTION_SELECTORS, IDIAMONDCUT_ID

@external
func __init_facet__() -> () {
    return ();
}

@view
func __get_function_selectors__() -> (res_len: felt, res: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (res_len=3, res=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.DIAMONDCUT.diamondCut;
    dw FUNCTION_SELECTORS.DIAMONDCUT.setAlias;
    dw FUNCTION_SELECTORS.DIAMONDCUT.setFunctionFee;
}

// / @dev ERC-165
@view
func __supports_interface__(_interface_id: felt) -> (success: felt) {
    if (_interface_id == IDIAMONDCUT_ID) {
        return (TRUE,);
    }
    return (FALSE,);
}
