%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, split_felt
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from src.constants import IERC721_ID, IERC721_METADATA_ID, IERC165_ID, NULL
from src.ERC5185.library import ERC5185
from src.ERC721.library import ERC721, ERC721Library
from src.Factory.library import Factory
from src.Proxy.library import Proxy
from src.UniversalMetadata.library import UniversalMetadata


/// @dev facet key for resolving DiamondCut
const DIAMOND_CUT_ONLY = 1;

/// @dev Set proxy_target
/// @param _contract_hash Class hash of to-be-deployed contracts
/// @param _proxy_target Forward all calls and invokes to this address
/// @param _name ERC721 contract name
/// @param _symbol ERC721 contract symbol
/// @param _uri ERC721 token URI
@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _contract_hash: felt,
    _proxy_target: felt,
    _name: felt,
    _symbol: felt,
    _uri_len: felt,
    _uri: felt*,
) {
    alloc_locals;
    let (local NULLptr: felt*) = alloc();
    Factory._set_contract_hash_(_contract_hash);
    Proxy._set_proxy_target_(_proxy_target);
    UniversalMetadata._set_name_(_name);
    UniversalMetadata._set_symbol_(_symbol);
    UniversalMetadata._set_token_uri_(_uri_len, _uri, FALSE, NULL, NULLptr);
    return ();
}

/// @dev Proxy all requests
@external
@raw_input
@raw_output
func __default__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    selector: felt, calldata_size: felt, calldata: felt*
) -> (retdata_size: felt, retdata: felt*) {
    return Proxy._proxy(selector, calldata_size, calldata);
}

@view
func getProxyTarget{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    res: felt
) {
    let target_address = Proxy._get_proxy_target_();
    return (res=target_address);
}

@view
func getContractHash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    res: felt
) {
    let contract_hash = Factory._get_contract_hash_();
    return (res=contract_hash);
}

/// @dev Mint lazily NFT and deploy contract
/// @notice Minted diamond is unfinished
/// @emit DeployContract
/// @emit Transfer
/// @return Address of the deployed contract
@external
func mintContract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    res: felt
) {
    alloc_locals;
    let (calldata_len, calldata) = _assemble_constructor_calldata();
    let contract_address = Factory._deploy_contract(calldata_len, calldata);
    let token_id = _compute_token_id(contract_address);
    let (owner) = get_caller_address();
    ERC721._mint(owner, token_id);
    return (res=contract_address);
}

func _assemble_constructor_calldata{syscall_ptr: felt*}() -> (
    calldata_len: felt, calldata: felt*
) {
    alloc_locals;
    let (local calldata: felt*) = alloc();
    let (root) = get_contract_address();
    assert calldata[0] = root;
    assert calldata[1] = DIAMOND_CUT_ONLY;
    return (calldata_len=2, calldata=calldata);
}

func _compute_token_id{range_check_ptr}(address) -> Uint256 {
    let (high, low) = split_felt(address);
    let token_id = Uint256(low, high);
    return token_id;
}

/// @dev Publish public information about contracts
/// @emit UpdateMetadata
/// @revert UNAUTHORIZED if caller is not owner of tokenId
@external
func updateMetadata{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _tokenId: Uint256, _type: felt, _data_len: felt, _data: felt*
) -> () {
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

/// @revert ZERO ADDRESS if _owner is 0
@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_owner: felt) -> (
    res: Uint256
) {
    let balance = ERC721._balanceOf(_owner);
    return (res=balance);
}

/// @revert INVALID TOKEN ID
/// @revert UNKNOWN TOKEN ID
@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _tokenId: Uint256
) -> (res: felt) {
    let is_owner = ERC721._ownerOf(_tokenId);
    return (res=is_owner);
}

/// @revert INVALID TOKEN ID
/// @revert UNKNOWN TOKEN ID
@view
func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _tokenId: Uint256
) -> (res: felt) {
    let operator = ERC721._getApproved(_tokenId);
    return (res=operator);
}

/// @revert ZERO ADDRESS if either _owner or _operator is 0
@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _owner: felt, _operator: felt
) -> (res: felt) {
    let is_approved = ERC721._isApprovedForAll(_owner, _operator);
    return (res=is_approved);
}

/// @revert UNKNOWN TOKEN ID
@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _tokenId: Uint256
) -> (res_len: felt, res: felt*) {
    ERC721Library._assert_minted(_tokenId);
    let (uri_len, uri) = UniversalMetadata._get_token_uri_(_tokenId);
    return (uri_len, uri);
}

/// @emit Approval
/// @revert INVALID TOKEN ID
/// @revert UNAUTHORIZED if caller is neither owner nor oeprator
/// @revert DISABLED FOR OWNER
@external
func approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _to, _tokenId: Uint256
) -> () {
    ERC721._approve(_to, _tokenId);
    return ();
}

/// @emit ApprovalForAll
/// @revert ZERO ADDRESS if _operator or caller is 0
/// @revert SELF APPROVAL if _operator equals caller
@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _operator: felt, _approved: felt
) -> () {
    ERC721._setApprovalForAll(_operator, _approved);
    return ();
}

/// @emit Transfer
/// @revert INVALID TOKEN ID
/// @revert UNKNOWN TOKEN ID
/// @revert UNAUTHORIZED if caller is neither owner nor oeprator
/// @revert INVALID FROM if from is not owner of token id
/// @revert ZERO ADDRESS if _to is 0
@external
func transferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt, _to: felt, _tokenId: Uint256
) -> () {
    ERC721._transferFrom(_from, _to, _tokenId);
    return ();
}

/// @emit Transfer
/// @revert INVALID TOKEN ID
/// @revert UNKNOWN TOKEN ID
/// @revert UNAUTHORIZED if caller is neither owner nor oeprator
/// @revert INVALID FROM if from is not owner of token id
/// @revert ZERO ADDRESS if _to is 0
/// @revert NOT RECEIVED
@external
func safeTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt, _to: felt, _tokenId: Uint256, data_len: felt, data: felt*
) -> () {
    let (caller) = get_caller_address();
    ERC721._safeTransferFrom(_from, _to, _tokenId, data_len, data);
    return ();
}

/// @emit Transfer
/// @revert INVALID TOKEN ID
/// @revert UNKNOWN TOKEN ID
/// @revert UNAUTHORIZED if caller is not owner
@external
func burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _tokenId: Uint256
) -> () {
    ERC721._burn(_tokenId);
    return ();
}

/// @dev ERC165
@view
func supportsInterface(interfaceID: felt) -> (res: felt) {
    if (interfaceID == IERC165_ID) {
        return (res=TRUE);
    }
    if (interfaceID == IERC721_ID) {
        return (res=TRUE);
    }
    if (interfaceID == IERC721_METADATA_ID) {
        return (res=TRUE);
    }
    return (res=FALSE);
}
