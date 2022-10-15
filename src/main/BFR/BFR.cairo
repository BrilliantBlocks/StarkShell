%lang starknet
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin

from src.BFR.library import BFR
from src.AccessManagement.Ownership.library import Ownership

// / @emit SetOwner(_owner)
@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_owner: felt) {
    Ownership._set_owner_(_owner);
    return ();
}

// / @dev Register element in bitmap
// / @emit Register(_bitId, _element)
// / @revert ZERO ELEMENT if _element is 0
// / @revert DUPLICATE ELEMENT if _element is already in bitmap
@external
func registerElement{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(_element: felt) -> () {
    Ownership._assert_only_owner();
    BFR._register_element(_element);
    return ();
}

// / @dev Register elements in bitmap
// / @emit Register(_bitId, _element)
// / @revert ZERO ELEMENT if _element is 0
// / @revert DUPLICATE ELEMENT if _element is already in bitmap
@external
func registerElements{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(_elements_len: felt, _elements: felt*) -> () {
    Ownership._assert_only_owner();
    BFR._register_elements(_elements_len, _elements);
    return ();
}

// / @dev Resolve key from bitmap
// / @revert TODO
// / @return Array of stored elements
@view
func resolveKey{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(_key: felt) -> (res_len: felt, res: felt*) {
    let (res_len, res) = BFR._resolve_key(_key);
    return (res_len, res);
}

// / @dev Calculate key for array of elements
// / @revert ZERO ELEMENT if 0 is in array
// / @revert DUPLICATE ELEMENT if array is not a set
// / @revert UNKNOWN ELEMENT if element not stored in bitmap
// / @return Key for resolving array of elements
@view
func calculateKey{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(_el_len: felt, _el: felt*) -> (res: felt) {
    let key = BFR._calculate_key(_el_len, _el);
    return (res=key);
}

@view
func getOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let owner = Ownership._get_owner_();
    return (res=owner);
}

// / @emit SetOwner(_owner)
// / @revert UNAUTHORIZED iff caller is not owner
@external
func setOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_owner: felt) {
    Ownership._assert_only_owner();
    Ownership._set_owner_(_owner);
    return ();
}
