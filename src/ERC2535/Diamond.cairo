%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import library_call
from src.constants import IERC165_ID, IDIAMONDLOUPE_ID
from src.ERC2535.library import Diamond


/// @param _root: Address of TCF
/// @param _facet_key Bitmap encoding included facets
/// @param _init_calldata TODO
@constructor
func constructor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(_root: felt, _facet_key: felt) {
    Diamond._set_facet_key_(_facet_key);
    Diamond._set_root_(_root);
    return ();
}

/// @revert UNKNOWN FUNCTION if selector not found in any facet
@external
@raw_input
@raw_output
func __default__{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(selector: felt, calldata_size: felt, calldata: felt*) -> (retdata_size: felt, retdata: felt*) {
    let (facet: felt) = facetAddress(selector);
    let (retdata_size: felt, retdata: felt*) = library_call(
        class_hash=facet, function_selector=selector, calldata_size=calldata_size, calldata=calldata
    );
    Diamond._charge_fee();
    return (retdata_size, retdata);
}

/// @return Array of included class hashes
@view
func facetAddresses{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}() -> (res_len: felt, res: felt*) {
    let (facets_len, facets) = Diamond._facetAddresses();
    return (facets_len, facets);
}

/// @dev Resolve alias as if they were the actual function
/// @revert UNKNOWN FUNCTION if selector not found in any facet
/// @return Class hash implementing _functionSelector
@view
func facetAddress{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(_functionSelector: felt) -> (res: felt) {
    let resolved_alias = Diamond._getAlias(_functionSelector);
    if (resolved_alias == 0) {
        let (class_hash) = Diamond._facetAddress(_functionSelector);
    } else {
        let (class_hash) = Diamond._facetAddress(resolved_alias);
    }
    return (res=class_hash);
}

/// @revert FACET NOT FOUND
/// @return Array of selectors implemented in a facet
@view
func facetFunctionSelectors{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(_facet: felt) -> (res_len: felt, res: felt*) {
    Diamond.Assert.facet_exists(_facet);
    let (selectors_len, selectors) = Diamond._facetFunctionSelectors(_facet);
    return (selectors_len, selectors);
}

/// @dev Same as facetAddresses()
/// @return Array of included class hashes
@view
func facets{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}() -> (res_len: felt, res: felt*) {
    return facetAddresses();
}

/// @dev Calls all facets for their supported interfaces
@view
func supportsInterface{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(interface_id: felt) -> (res: felt) {
    alloc_locals;
    if (interface_id == IERC165_ID) {
        return (res=TRUE);
    }
    if (interface_id == IDIAMONDLOUPE_ID) {
        return (res=TRUE);
    }
    let (facets_len, facets) = facetAddresses();
    return Diamond._supportsInterface(interface_id, facets_len, facets);
}

/// @dev Aspect requires this function for token type detection
/// @notice The respective facet must be included at deploy time
/// @return Class hash of token type. Return 0 if no token is included
@view
func getImplementation{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}() -> (res: felt) {
    let (facets_len, facets) = facetAddresses();
    let token_facet = Diamond._find_token_facet(facets_len, facets);
    return (res=token_facet);
}

/// @return Address of root factory
@view
func getRoot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let root = Diamond._get_root_();
    return (res=root);
}
