%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC721 {
    func name() -> (res: felt) {
    }

    func symbol() -> (res: felt) {
    }

    func balanceOf(_owner: felt) -> (res: Uint256) {
    }

    func ownerOf(_tokenId: Uint256) -> (res: felt) {
    }

    func getApproved(_tokenId: Uint256) -> (res: felt) {
    }

    func isApprovedForAll(_owner: felt, _operator: felt) -> (res: felt) {
    }

    func tokenURI(_tokenId: Uint256) -> (tokenURI_len: felt, tokenURI: felt*) {
    }

    func approve(_to: felt, _tokenId: Uint256) -> () {
    }

    func setApprovalForAll(_operator: felt, _approved: felt) -> () {
    }

    func transferFrom(_from: felt, _to: felt, _tokenId: Uint256) -> () {
    }

    func safeTransferFrom(
        _from: felt, _to: felt, _tokenId: Uint256, data_len: felt, data: felt*
    ) -> () {
    }

    func setTokenURI(tokenURI_len: felt, tokenURI: felt*) -> () {
    }
}
