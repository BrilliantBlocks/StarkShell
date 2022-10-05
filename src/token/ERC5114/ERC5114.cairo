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
func Mint(sbt_id: Uint256, nft: NFT) {
}


@storage_var
func _owners(sbt_id: Uint256) -> (nft: NFT) {
}


@storage_var
func _collection_uri() -> (res: felt) {
}


@storage_var
func _metadata_format() -> (res: felt) {
}


@external
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    sbt_id: Uint256, nft: NFT
) -> () {

    assert_initialized();
    
    with_attr error_message("SBT is not a valid Uint256") {
        uint256_check(sbt_id);
    }
    with_attr error_message("NFT is not a valid Uint256") {
        uint256_check(nft.id);
    }

    let (exists) = _exists(sbt_id);
    with_attr error_message("SBT already bound") {
        assert exists = FALSE;
    }

    _owners.write(sbt_id, nft);
    Mint.emit(sbt_id, nft);
    return ();
}



@view
func ownerOf{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    sbt_id: Uint256
) -> (nft: NFT) {

    assert_initialized();

    with_attr error_message("SBT input must be a Uint256") {
        uint256_check(sbt_id);
    }
    let (nft) = _owners.read(sbt_id);

    with_attr error_message("SBT is nonexistent") {
        assert_not_zero(nft.address);
    }

    return (nft,);
}


@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    sbt_id: Uint256
) -> (sbt_uri_len: felt, sbt_uri: felt*) {
    alloc_locals;
    assert_initialized();

    let (exists) = _exists(sbt_id);
    with_attr error_message("SBT is nonexistent") {
        assert exists = TRUE;
    }

    let (collection_uri) = _collection_uri.read();
    let (collection_uri_ss_len, collection_uri_ss) = felt_to_ss(collection_uri);
    let (sbt_id_ss_len, sbt_id_ss) = uint256_to_ss(sbt_id);

    let (sbt_uri_len, sbt_uri) = concat_array(
        collection_uri_ss_len, collection_uri_ss, sbt_id_ss_len, sbt_id_ss);

    return (sbt_uri_len, sbt_uri);
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


@view
func collectionURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    collection_uri: felt
) {
    assert_initialized();

    let (collection_uri) = _collection_uri.read();

    return (collection_uri,);
}


@view
func metadataFormat{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    metadata_format: felt
) {
    assert_initialized();

    let (metadata_format) = _metadata_format.read();

    return (metadata_format,);
}


func _exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    sbt_id: Uint256
) -> (bool: felt) {
    
    let (exists) = _owners.read(sbt_id);
    
    if (exists.address == FALSE) {
        return (FALSE,);
    }

    return (TRUE,);
}


func assert_initialized{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    
    let (collection_uri) = _collection_uri.read();
    with_attr error_message("You must initialize the contract") {
        assert_not_zero(collection_uri);
    }

    return ();
}


@external
func __init_facet__{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    collection_uri: felt, metadata_format: felt
) -> () {
    
    with_attr error_message("Collection URI must not be zero") {
        assert_not_zero(collection_uri);
    }
    with_attr error_message("Metadata format must not be zero") {
        assert_not_zero(metadata_format);
    }

    _collection_uri.write(collection_uri);
    _metadata_format.write(metadata_format);

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