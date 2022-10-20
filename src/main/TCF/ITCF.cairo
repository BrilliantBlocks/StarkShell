%lang starknet
from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace ITCF {
    func getContractHash() -> (res: felt) {
    }

    func getProxyTarget() -> (res: felt) {
    }

    func mintContract() -> (res: felt) {
    }

    func updateMetadata(_tokenId: felt, _type: felt, _data_len: felt, _data: felt*) -> () {
    }

    ///////// ERC721 /////////

    func approve(_to: felt, _tokenId: Uint256) -> () {
    }

    func balanceOf(_owner: felt) -> (res: Uint256) {
    }

    func getApproved(_tokenId: Uint256) -> (res: felt) {
    }

    func isApprovedForAll(_owner: felt, _operator: felt) -> (res: felt) {
    }

    func ownerOf(_tokenId: Uint256) -> (res: felt) {
    }

    func safeTransferFrom(
        _from: felt, _to: felt, _tokenId: Uint256, data_len: felt, data: felt*
    ) -> () {
    }

    func setApprovalForAll(_operator: felt, _approved: felt) -> () {
    }

    func transferFrom(_from: felt, _to: felt, _tokenId: Uint256) -> () {
    }

    ///////// ERC721Metadata /////////

    func name() -> (res: felt) {
    }

    func symbol() -> (res: felt) {
    }

    func tokenURI(_tokenId: Uint256) -> (tokenURI_len: felt, tokenURI: felt*) {
    }

    ///////// Burnable /////////
    func burn(_tokenId: Uint256) -> () {
    }

    ///////// ERC165 /////////

    func supportsInterface(interfaceID: Uint256) -> (res: felt) {
    }
}
