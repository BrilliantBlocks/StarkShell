%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_le, assert_not_equal, assert_not_zero
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    library_call,
)
from src.constants import (
    IERC165_ID,
    IERC20_ID,
    IERC721_ID,
    IERC1155_ID,
    IERC5114_ID,
    IDIAMONDLOUPE_ID,
    FUNCTION_SELECTORS,
    NULL,
)
from src.ERC2535.DiamondLoupe import (
    facetAddress,
    facetAddresses,
    facetFunctionSelectors,
    facets,
)
from src.storage import facet_key, root


// @param _root: Address of TCF
@constructor
func constructor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(_root: felt, _facet_key: felt) {
    facet_key.write(_facet_key);
    root.write(_root);
    return ();
}


// @dev
// @param
// @return
@external
@raw_input
@raw_output
func __default__{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(selector: felt, calldata_size: felt, calldata: felt*) -> (retdata_size: felt, retdata: felt*) {
    let (facet: felt) = facetAddress(selector);

    with_attr error_message("FACET NOT FOUND") {
        assert_not_zero(facet);
    }

    let (retdata_size: felt, retdata: felt*) = library_call(
        class_hash=facet, function_selector=selector, calldata_size=calldata_size, calldata=calldata
    );

    return (retdata_size, retdata);
}

// @dev Support ERC-165
// @param interface_id
// @return success (0 or 1)
@view
func supportsInterface{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(interface_id: felt) -> (res: felt) {
    alloc_locals;
    if (interface_id == IERC165_ID) {
        return (TRUE,);
    }

    if (interface_id == IDIAMONDLOUPE_ID) {
        return (TRUE,);
    }

    let (facets_len, facets) = facetAddresses();

    return _supportsInterface(interface_id, facets_len, facets);
}

// @dev
// @return
func _supportsInterface{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(interface_id: felt, facets_len: felt, facets: felt*) -> (res: felt) {
    alloc_locals;
    if (facets_len == 0) {
        return (FALSE,);
    }

    let (facet_supports_interface: felt) = _supportsInterfaceLibrary(interface_id, facets[0]);

    if (facet_supports_interface == TRUE) {
        return (TRUE,);
    }

    return _supportsInterface(interface_id, facets_len - 1, facets + 1);
}

func _find_token_facet{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(facets_len: felt, facets: felt*) -> (res: felt) {
    if (facets_len == 0) {
        return (NULL,);
    }

    let (is_token_facet) = _any_token_facet(facets[0]);
    if (is_token_facet == TRUE) {
        return (facets[0],);
    }

    return _find_token_facet(facets_len - 1, facets + 1);
}

func _any_token_facet{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _facet: felt
) -> (res: felt) {
    let (is_erc20_facet: felt) = _supportsInterfaceLibrary(IERC20_ID, _facet);
    if (is_erc20_facet == TRUE) {
        return (TRUE,);
    }

    let (is_erc721_facet: felt) = _supportsInterfaceLibrary(IERC721_ID, _facet);
    if (is_erc721_facet == TRUE) {
        return (TRUE,);
    }

    let (is_erc1155_facet: felt) = _supportsInterfaceLibrary(IERC1155_ID, _facet);
    if (is_erc1155_facet == TRUE) {
        return (TRUE,);
    }

    let (is_erc5114_facet: felt) = _supportsInterfaceLibrary(IERC5114_ID, _facet);
    if (is_erc5114_facet == TRUE) {
        return (TRUE,);
    }

    return (FALSE,);
}

func _supportsInterfaceLibrary{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _interface_id: felt, _facet: felt
) -> (res: felt) {
    alloc_locals;

    let (local param: felt*) = alloc();
    assert param[0] = _interface_id;

    let (r_len, r) = library_call(
        class_hash=_facet,
        function_selector=FUNCTION_SELECTORS.FACET.__supports_interface__,
        calldata_size=1,
        calldata=param,
    );

    return (r[0],);
}

// @dev Aspect requires this function for token type detection
// @notice The respective facet must be included at deploy time
// @return Class hash of token type. Return 0 if no token is included
@view
func getImplementation{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}() -> (res: felt) {
    let (facets_len, facets) = facetAddresses();

    return _find_token_facet(facets_len, facets);
}
