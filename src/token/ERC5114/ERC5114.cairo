%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.uint256 import Uint256, uint256_check
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.memcpy import memcpy

from src.constants import FUNCTION_SELECTORS, IERC5114_ID
from src.token.ERC721.util.ShortString import uint256_to_ss, felt_to_ss


struct NFT {
    address: felt,
    id: Uint256,
}


@event
func Mint(token_id: Uint256, nft: NFT) {
}


@storage_var
func _owners(token_id: Uint256) -> (nft: NFT) {
}

@storage_var
func _metadata_format() -> (res: felt) {
}

@storage_var
func _collection_uri() -> (res: felt) {
}

@storage_var
func _base_token_uri(index: felt) -> (res: felt) {
}

@storage_var
func _base_token_uri_len() -> (res: felt) {
}



@external
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    token_id: Uint256, nft: NFT
) -> () {
    
    with_attr error_message("SBT is not a valid Uint256") {
        uint256_check(token_id);
    }
    with_attr error_message("NFT is not a valid Uint256") {
        uint256_check(nft.id);
    }

    let (exists) = _exists(token_id);
    with_attr error_message("SBT already bound") {
        assert exists = FALSE;
    }

    _owners.write(token_id, nft);
    Mint.emit(token_id, nft);
    return ();
}


@view
func ownerOf{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    token_id: Uint256
) -> (nft: NFT) {

    with_attr error_message("SBT input must be a Uint256") {
        uint256_check(token_id);
    }
    let (nft) = _owners.read(token_id);

    with_attr error_message("SBT is nonexistent") {
        assert_not_zero(nft.address);
    }

    return (nft,);
}


@view
func metadataFormat{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    metadata_format: felt
) {
    let (metadata_format) = _metadata_format.read();

    return (metadata_format,);
}


@view
func collectionURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    collection_uri: felt
) {
    let (collection_uri) = _collection_uri.read();

    return (collection_uri,);
}


@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (token_uri_len: felt, token_uri: felt*) {
    let (token_uri_len: felt, token_uri: felt*) = long_token_uri(token_id);
    return (token_uri_len, token_uri);
}


func long_token_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (token_uri_len: felt, token_uri: felt*) {
    alloc_locals;

    let (exists) = _exists(token_id);
    with_attr error_message("Token is nonexistent.") {
        assert exists = TRUE;
    }

    // Return tokenURI with an array of felts, `${base_token_uri}/${token_id}`
    let (local base_token_uri) = alloc();
    let (local base_token_uri_len) = _base_token_uri_len.read();
    base_token_uri_(base_token_uri_len, base_token_uri);
    let (token_id_ss_len, token_id_ss) = uint256_to_ss(token_id);
    let (token_uri_len, token_uri) = concat_array(
        base_token_uri_len, base_token_uri, token_id_ss_len, token_id_ss);
    return (token_uri_len, token_uri);
}


func base_token_uri_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    base_token_uri_len: felt, base_token_uri: felt*
) -> () {
    if (base_token_uri_len == 0) {
        return ();
    }
    let (base) = _base_token_uri.read(base_token_uri_len);
    assert base_token_uri[0] = base;
    base_token_uri_(base_token_uri_len - 1, base_token_uri + 1);
    return ();
}


func set_base_token_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_uri_len: felt, token_uri: felt*
) -> () {
    populate_base_token_uri(token_uri_len, token_uri);
    _base_token_uri_len.write(token_uri_len);
    return ();
}


func populate_base_token_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_uri_len: felt, token_uri: felt*
) -> () {
    if (token_uri_len == 0) {
        return ();
    }
    _base_token_uri.write(token_uri_len, token_uri[0]);
    populate_base_token_uri(token_uri_len - 1, token_uri + 1);
    return ();
}


func concat_array{range_check_ptr}(
    arr1_len: felt, arr1: felt*, arr2_len: felt, arr2: felt*
) -> (res_len: felt, res: felt*) {
    alloc_locals;
    let (local res: felt*) = alloc();
    memcpy(res, arr1, arr1_len);
    memcpy(res + arr1_len, arr2, arr2_len);
    return (arr1_len + arr2_len, res);
}


func _exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (bool: felt) {
    
    let (exists) = _owners.read(token_id);
    
    if (exists.address == FALSE) {
        return (FALSE,);
    }

    return (TRUE,);
}


@external
func __init_facet__{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    metadata_format: felt, collection_uri: felt, token_uri_len: felt, token_uri: felt*
) -> () {
    
    with_attr error_message("Metadata format must not be zero") {
        assert_not_zero(metadata_format);
    }
    with_attr error_message("Collection URI must not be zero") {
        assert_not_zero(collection_uri);
    }

    _metadata_format.write(metadata_format);
    _collection_uri.write(collection_uri);
    set_base_token_uri(token_uri_len, token_uri);

    return ();
}


@view
func __get_function_selectors__() -> (res_len: felt, res: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (res_len=5, res=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.ERC5114.mint;
    dw FUNCTION_SELECTORS.ERC5114.ownerOf;
    dw FUNCTION_SELECTORS.ERC5114.tokenURI;
    dw FUNCTION_SELECTORS.ERC5114.collectionURI;
    dw FUNCTION_SELECTORS.ERC5114.metadataFormat;
}


// @dev Support ERC-165
// @param interface_id
// @return success (0 or 1)
@view
func __supports_interface__(_interface_id: felt) -> (success: felt) {
    if (_interface_id == IERC5114_ID) {
        return (TRUE,);
    }

    return (FALSE,);
}