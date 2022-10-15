%lang starknet
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin

from lib.cairo_contracts.src.openzeppelin.access.ownable.library import Ownable

from src.BFR.library import BFR

/// @emit OwnershipTransferred
@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_owner: felt) {
    Ownable.initializer(_owner);
    return ();
}

/// @dev Register element in bitmap
/// @emit Register(_bitId, _element)
/// @revert "Ownable: caller is the zero address"
/// @revert "Ownable: caller is not the owner"
/// @revert ZERO ELEMENT if _element is 0
/// @revert DUPLICATE ELEMENT if _element is already in bitmap
/// @revert FULL REGISTRY
@external
func registerElement{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(_element: felt) -> () {
    Ownable.assert_only_owner();
    BFR._register_element(_element);
    return ();
}

/// @dev Register elements in bitmap
/// @emit Register(_bitId, _element)
/// @revert "Ownable: caller is the zero address"
/// @revert "Ownable: caller is not the owner"
/// @revert ZERO ELEMENT if _element is 0
/// @revert DUPLICATE ELEMENT if _element is already in bitmap
/// @revert FULL REGISTRY
@external
func registerElements{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(_elements_len: felt, _elements: felt*) -> () {
    Ownable.assert_only_owner();
    BFR._register_elements(_elements_len, _elements);
    return ();
}

/// @dev Resolve key from bitmap
/// @return Array of stored elements
@view
func resolveKey{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(_key: felt) -> (res_len: felt, res: felt*) {
    let (res_len, res) = BFR._resolve_key(_key);
    return (res_len, res);
}

/// @dev Calculate key for array of elements
/// @revert ZERO ELEMENT if 0 is in array
/// @revert DUPLICATE ELEMENT if array is not a set
/// @revert UNKNOWN ELEMENT if element not stored in bitmap
/// @return Key for resolving array of elements
@view
func calculateKey{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(_el_len: felt, _el: felt*) -> (res: felt) {
    let key = BFR._calculate_key(_el_len, _el);
    return (res=key);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let (owner) = Ownable.owner();
    return (res=owner);
}

/// @emit OwnershipTransferred
/// @revert "Ownable: new owner is the zero address"
/// @revert "Ownable: caller is the zero address"
/// @revert "Ownable: caller is not the owner"
@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_new_owner: felt) -> () {
    Ownable.transfer_ownership(_new_owner);
    return ();
}

/// @emit OwnershipTransferred
/// @revert "Ownable: caller is the zero address"
/// @revert "Ownable: caller is not the owner"
@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    Ownable.renounce_ownership();
    return ();
}
