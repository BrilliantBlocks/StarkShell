%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.registers import get_label_location

from src.zkode.constants import FUNCTION_SELECTORS
from src.zkode.facets.storage.feltmap.library import FeltMap

// @dev Register element in bitmap
// @emit Register(_bitId, _element)
// @revert ZERO ELEMENT if _element is 0
// @revert DUPLICATE ELEMENT if _element is already in bitmap
@external
func registerElement{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(_element: felt) -> () {
    FeltMap._register_element(_element);

    return ();
}

// @dev Register elements in bitmap
// @emit Register(_bitId, _element)
// @revert ZERO ELEMENT if _element is 0
// @revert DUPLICATE ELEMENT if _element is already in bitmap
@external
func registerElements{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(_elements_len: felt, _elements: felt*) -> () {
    FeltMap._register_elements(_elements_len, _elements);

    return ();
}

// @dev Resolve key from bitmap
// @revert TODO
// @return Array of stored elements
@view
func resolveKey{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(_key: felt) -> (res_len: felt, res: felt*) {
    let (res_len, res) = FeltMap._resolve_key(_key);

    return (res_len, res);
}

// @dev Calculate key for array of elements
// @revert ZERO ELEMENT if 0 is in array
// @revert DUPLICATE ELEMENT if array is not a set
// @revert UNKNOWN ELEMENT if element not stored in bitmap
// @return Key for resolving array of elements
@view
func calculateKey{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(_el_len: felt, _el: felt*) -> (res: felt) {
    let key = FeltMap._calculate_key(_el_len, _el);

    return (res=key);
}

// ===============
// Facet Detection
// ===============
@external
func __constructor__{
    syscall_ptr: felt*, bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(_felts_len: felt, _felts: felt*) {
    alloc_locals;

    FeltMap._register_elements(_felts_len, _felts);

    return ();
}

@external
func __destructor__() -> () {
    return ();
}

@view
@raw_output
func __API__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    retdata_size: felt, retdata: felt*
) {
    let (func_selectors) = get_label_location(selectors_start);
    return (retdata_size=2, retdata=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.IFeltMap.registerElement;
    dw FUNCTION_SELECTORS.IFeltMap.registerElements;
}

@view
@raw_output
func __pub_func__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    retdata_size: felt, retdata: felt*
) {
    alloc_locals;

    let (func_selectors) = get_label_location(selectors_start);

    return (retdata_size=2, retdata=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.IFeltMap.calculateKey;
    dw FUNCTION_SELECTORS.IFeltMap.resolveKey;
}

@view
func __supports_interface__(_interfaceId: felt) -> (res: felt) {
    return (res=FALSE);
}
