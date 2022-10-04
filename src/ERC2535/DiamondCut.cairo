%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.math import split_felt
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    library_call,
)
from starkware.cairo.common.registers import get_label_location

from src.constants import FUNCTION_SELECTORS, IDIAMONDCUT_ID
from src.storage import facet_key, root
from src.token.ERC721.IERC721 import IERC721
from src.FacetRegistry.IRegistry import IRegistry
from src.ERC2535.DiamondLoupe import facetAddresses, facetAddress

@event
func DiamondCut(
    _address: felt, _facetCutAction: felt, _init: felt, _calldata_len: felt, _calldata: felt*
) {
}

// Enum
struct FacetCutAction {
    Add: felt,
    Replace: felt,
    Remove: felt,
}

// @dev
// @return
@external
func diamondCut{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(_address: felt, _facetCutAction: felt, _init: felt, _calldata_len: felt, _calldata: felt*) -> () {
    alloc_locals;

    let (caller) = get_caller_address();
    let  owner = get_owner();

    with_attr error_message("YOU MUST BE THE OWNER TO CALL THE FUNCTION") {
        assert caller = owner;
    }

    if (_facetCutAction == FacetCutAction.Add) {
        return _add_facet(_address, _init, _calldata_len, _calldata);
    } else {
        return _remove_facet(_address);
    }
}


func get_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
    alloc_locals;

    let root = getRootDiamond();
    let tokenId = getRootTokenId();
    let (owner) = IERC721.ownerOf(root, tokenId);

    return owner;
}


func getRootDiamond{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt{
    let (r) = root.read();
    let (self) = get_contract_address();

    if (r == 0) {
        return self;
    } else {
        return r;
    }
}


func getRootTokenId{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> Uint256 {
    alloc_locals;
    let (r) = root.read();

    if (r == 0) {
        local tokenId: Uint256 = Uint256(0, 0);

        return tokenId;
    } else {
        let (self) = get_contract_address();
        let (high, low) = split_felt(self);
        local tokenId: Uint256 = Uint256(low, high);

        return tokenId;
    }
}


func _add_facet{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(_address: felt, _init: felt, _calldata_len: felt, _calldata: felt*) -> () {
    alloc_locals;
    let root = getRootDiamond();

    // Get facets and append new facet
    let (facets_len, facets) = facetAddresses();
    assert facets[facets_len] = _address;

    let (new_key) = IRegistry.calculateKey(root, facets_len + 1, facets);

    facet_key.write(new_key);

    initFacet(_address, _calldata_len, _calldata);

    return ();
}


func initFacet{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    class_hash: felt, calldata_len: felt, calldata: felt*
    ) -> () {
    library_call(
        class_hash=class_hash,
        function_selector=FUNCTION_SELECTORS.FACET.__init_facet__,
        calldata_size=calldata_len,
        calldata=calldata,
    );

    return ();
}


func _remove_facet{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(_address: felt) -> () {
    alloc_locals;

    let (key) = facet_key.read();
    let (r) = root.read();

    let (facets_len, facets) = facetAddresses();

    // find it
    let (x) = _remove_facet_helper(facets_len, facets, _address, 0);
    let (local ptr: felt*) = alloc();
    memcpy(dst=ptr, src=facets, len=x);

    // if non-tail element is removed
    if (facets_len != x + 1) {
        memcpy(dst=ptr + x, src=facets + x + 1, len=facets_len - x - 1);  // TODO
    }

    if (r != 0) {
        let (new_key) = IRegistry.calculateKey(r, facets_len - 1, ptr);
    } else {
        let (my_root) = get_contract_address();
        let (new_key) = IRegistry.calculateKey(my_root, facets_len - 1, ptr);
    }

    facet_key.write(new_key);

    return ();
}

func _remove_facet_helper{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _f_len: felt, _f: felt*, _target: felt, _id: felt
) -> (res: felt) {
    if (_f_len == 0) {
        with_attr error_message("FACET DOES NOT EXIST") {
            assert 1 = 0;
        }
    }
    if (_target == _f[0]) {
        return (_id,);
    }

    return _remove_facet_helper(_f_len - 1, _f + 1, _target, _id + 1);
}

@external
func __init_facet__{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(x: felt) -> () {
    return ();
}

@view
func __get_function_selectors__{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    ) -> (res_len: felt, res: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (res_len=1, res=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.DIAMONDCUT.diamondCut;
}

// @dev Support ERC-165
// @param interface_id
// @return success (0 or 1)
// TODO remove implicit arguments?
@view
func __supports_interface__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _interface_id: felt
) -> (success: felt) {
    if (_interface_id == IDIAMONDCUT_ID) {
        return (TRUE,);
    }

    return (FALSE,);
}
