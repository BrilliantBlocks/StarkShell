%lang starknet
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_equal, assert_not_zero
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.registers import get_label_location
from starkware.starknet.common.syscalls import get_caller_address

from src.constants import FUNCTION_SELECTORS, IERC721_ID
from src.ERC721.library import ERC721, ERC721Library

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_owner: felt) -> (
    res: Uint256
) {
    let balance = ERC721._balanceOf(_owner);
    return (res=balance);
}

@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _tokenId: Uint256
) -> (res: felt) {
    let is_owner = ERC721._ownerOf(_tokenId);
    return (res=is_owner);
}

@view
func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _tokenId: Uint256
) -> (res: felt) {
    let operator = ERC721._getApproved(_tokenId);
    return (res=operator);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _owner: felt, _operator: felt
) -> (res: felt) {
    let is_approved = ERC721._isApprovedForAll(_owner, _operator);
    return (res=is_approved);
}

@external
func approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _to, _tokenId: Uint256
) -> () {
    ERC721._approve(_to, _tokenId);
    return ();
}

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _operator: felt, _approved: felt
) -> () {
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
func transferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt, _to: felt, _tokenId: Uint256
) -> () {
    let (caller) = get_caller_address();
    ERC721._transferFrom(_from, _to, _tokenId);
    return ();
}

@external
func safeTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt, _to: felt, _tokenId: Uint256, data_len: felt, data: felt*
) -> () {
    let (caller) = get_caller_address();
    ERC721._safeTransferFrom(_from, _to, _tokenId, data_len, data);
    return ();
}

// ===========================
// Interface for UniversalMint
// ===========================

// / @notice Not included in __get_function_selectors__()
// / @revert INVALID TOKEN ID
// / @revert ZERO ADDRESS
// / @revert EXISTING TOKEN ID
@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _to: felt, _tokenId: Uint256
) -> () {
    ERC721._mint(_to, _tokenId);
    return ();
}

// ===================
// Mandatory functions
// ===================

// @dev Initialize this facet
@external
func __constructor__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _to: felt, _tokenId_len: felt, _tokenId: Uint256*
) {
    alloc_locals;

    if (_tokenId_len == 0) {
        return ();
    }

    ERC721._mint(_to, _tokenId[0]);

    return __constructor__(_to, _tokenId_len - 1, _tokenId + Uint256.SIZE);
}

// @dev Remove this facet
@external
func __destructor__() {
    return ();
}

// @dev Exported view and invokable functions of this facet
@view
@raw_output
func __get_function_selectors__() -> (retdata_size: felt, retdata: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (retdata_size=8, retdata=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.ERC721.balanceOf;
    dw FUNCTION_SELECTORS.ERC721.ownerOf;
    dw FUNCTION_SELECTORS.ERC721.getApproved;
    dw FUNCTION_SELECTORS.ERC721.isApprovedForAll;
    dw FUNCTION_SELECTORS.ERC721.approve;
    dw FUNCTION_SELECTORS.ERC721.setApprovalForAll;
    dw FUNCTION_SELECTORS.ERC721.transferFrom;
    dw FUNCTION_SELECTORS.ERC721.safeTransferFrom;
}

// @dev Define all supported interfaces of this facet
@view
func __supports_interface__(_interface_id: felt) -> (res: felt) {
    if (_interface_id == IERC721_ID) {
        return (res=TRUE);
    }
    return (res=FALSE);
}
