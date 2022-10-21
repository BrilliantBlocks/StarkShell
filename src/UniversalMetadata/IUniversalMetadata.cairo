%lang starknet
from starkware.cairo.common.uint256 import Uint256


@contract_interface
namespace IUniversalMetadata {

    ///////// ERC721Metadata /////////

    /// @selector 0x361458367e696363fbcc70777d07ebbd2394e89fd0adcaf147faccd1d294d60
    func name() -> (res: felt) {
    }

    /// @selector 0x216b05c387bab9ac31918a3e61672f4618601f3c598a2f3f2710f37053e1ea4
    func symbol() -> (res: felt) {
    }

    /// @selector 0x12a7823b0c6bee58f8c694888f32f862c6584caa8afa0242de046d298ba684d
    func tokenURI(_tokenId: Uint256) -> (tokenURI_len: felt, tokenURI: felt*) {
    }

}
