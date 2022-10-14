%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_equal, assert_not_zero, split_felt
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from src.constants import IERC721_ID, IERC721_METADATA_ID, IERC165_ID
from src.ERC5185.library import ERC5185
from src.ERC721.library import ERC721, ERC721Library
from src.UniversalMetadata.library import UniversalMetadata
from src.Factory.library import Factory
from src.Proxy.library import Proxy


/// @dev Set target proxy
/// @param Address of proxy_target
@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_contract_hash: felt, _proxy_target: felt, _name: felt, _symbol: felt, _prefixURI_len: felt, _prefixURI: felt*, _hasInfixURI: felt, _suffixURI_len: felt, _suffixURI: felt*) {
    Factory._set_contract_hash_(_contract_hash);
    Proxy._set_proxy_target_(_proxy_target);
    UniversalMetadata._set_name_(_name);
    UniversalMetadata._set_symbol_(_symbol);
    UniversalMetadata._set_token_uri_(_prefixURI_len, _prefixURI, _hasInfixURI, _suffixURI_len, _suffixURI);
    return ();
}


@external
@raw_input
@raw_output
func __default__{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(selector: felt, calldata_size: felt, calldata: felt*) -> (retdata_size: felt, retdata: felt*) {
    return Proxy._proxy(selector, calldata_size, calldata);
}


@view
func getProxyTarget{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let target_address = Proxy._get_proxy_target_();
    return (res=target_address);
}


@view
func getContractHash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let contract_hash = Factory._get_contract_hash_();
    return (res=contract_hash);
}


/// @dev Mint lazily NFT and deploy contract
/// @emit DeployContract + Mint (?)
/// @return Address of the deployed contract
@external
func mintContract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_key: felt) -> (res: felt) {
    alloc_locals;
    let (local calldata: felt*) = alloc();
    let (owner) = get_caller_address();
    let (root) = get_contract_address();
    //let (calldata_len, calldata) = assembleCalldata(owner, _facet_key);
    let calldata_len = 2;
    assert calldata[0] = root;
    assert calldata[1] = _key;
    let contract_address = Factory._deploy_contract(calldata_len, calldata);
    // let contract_address = Factory._deploy_contract(owner, _key);
    let (high, low) = split_felt(contract_address);
    let token_id = Uint256(low, high);
    ERC721._mint(owner, token_id);
    return (res=contract_address);
}


/// @dev Publish public information about contracts
@external
func updateMetadata{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_tokenId: Uint256, _type: felt, _data_len: felt, _data: felt*) -> () {
    alloc_locals;
    ERC721._assertOnlyOwner(_tokenId);
    ERC5185._update_metadata(_tokenId, _type, _data_len, _data);
    return ();
}


@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let name = UniversalMetadata._get_name_();
    return (res=name);
}


@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let symbol = UniversalMetadata._get_symbol_();
    return (res=symbol);
}


@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_owner: felt) -> (res: Uint256) {
    let balance = ERC721._balanceOf(_owner);
    return (res=balance);
}


@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_tokenId: Uint256) -> (res: felt) {
    let is_owner = ERC721._ownerOf(_tokenId);
    return (res=is_owner);
}


@view
func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_tokenId: Uint256) -> (res: felt) {
    let operator = ERC721._getApproved(_tokenId);
    return (res=operator);
}


@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_owner: felt, _operator: felt) -> (res: felt) {
    let is_approved = ERC721._isApprovedForAll(_owner, _operator);
    return (res=is_approved);
}


@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_tokenId: Uint256) -> (res_len: felt, res: felt*) {
    ERC721Library._assert_minted(_tokenId);
    let (uri_len, uri) = UniversalMetadata._get_token_uri_(_tokenId);
    return (uri_len, uri);
}


@external
func approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_to, _tokenId: Uint256) -> () {
    ERC721._approve(_to, _tokenId);
    return ();
}


@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_operator: felt, _approved: felt) -> () {
    let (caller) = get_caller_address();
    with_attr error_message("Either the caller or operator is the zero address") {
        assert_not_zero(caller * _operator);
    }
    with_attr error_message("You cannot set approval for yourself.") {
        assert_not_equal(caller, _operator);
    }
    ERC721._setApprovalForAll(_operator, _approved);
    return ();
}


@external
func transferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_from: felt, _to: felt, _tokenId: Uint256) -> () {
    let (caller) = get_caller_address();
    ERC721._transferFrom(_from, _to, _tokenId);
    return ();
}


@external
func safeTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_from: felt, _to: felt, _tokenId: Uint256, data_len: felt, data: felt*) -> () {
    let (caller) = get_caller_address();
    ERC721._safeTransferFrom(_from, _to, _tokenId, data_len, data);
    return ();
}


/// @dev ERC165
@view
func supportsInterface(interfaceID: felt) -> (res: felt) {
    if (interfaceID == IERC165_ID) {
        return (TRUE,);
    }

    if (interfaceID == IERC721_ID) {
        return (TRUE,);
    }

    if (interfaceID == IERC721_METADATA_ID) {
        return (TRUE,);
    }

    return (FALSE,);
}
