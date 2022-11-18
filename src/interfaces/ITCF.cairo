%lang starknet
from starkware.cairo.common.uint256 import Uint256

from src.ERC2535.structs import FacetCut

@contract_interface
namespace ITCF {
    func getContractHash() -> (res: felt) {
    }

    func getProxyTarget() -> (res: felt) {
    }

    func mintContract(
        _facetCut_len: felt, _facetCut: FacetCut*, _calldata_len: felt, _calldata: felt*
    ) -> (res: felt) {
    }

    func updateMetadata(_tokenId: felt, _type: felt, _data_len: felt, _data: felt*) -> () {
    }

    // /////// ERC721 /////////

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

    // /////// ERC721Metadata /////////

    // / @selector 0x361458367e696363fbcc70777d07ebbd2394e89fd0adcaf147faccd1d294d60
    func name() -> (res: felt) {
    }

    // / @selector 0x216b05c387bab9ac31918a3e61672f4618601f3c598a2f3f2710f37053e1ea4
    func symbol() -> (res: felt) {
    }

    // / @selector 0x12a7823b0c6bee58f8c694888f32f862c6584caa8afa0242de046d298ba684d
    func tokenURI(_tokenId: Uint256) -> (tokenURI_len: felt, tokenURI: felt*) {
    }

    // /////// Burnable /////////
    func burn(_tokenId: Uint256) -> () {
    }

    // /////// ERC165 /////////

    func supportsInterface(interfaceID: Uint256) -> (res: felt) {
    }
}
