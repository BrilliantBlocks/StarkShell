%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_equal, assert_not_zero
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address

from src.ERC721.library import ERC721, ERC721Library

// Facet-specifix external and view functions
from src.ERC721.__ERC721 import (
    __constructor__,
    __destructor__,
    __get_function_selectors__,
    __supports_interface__,
)


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
