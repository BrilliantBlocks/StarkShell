%lang starknet
from starkware.cairo.common.uint256 import Uint256

struct NFT {
    address: felt,
    id: Uint256,
}

@contract_interface
namespace IERC5114 {
    // / @selector 0x2962ba17806af798afa6eaf4aa8c93a9fb60a3e305045b6eea33435086cae9
    func ownerOf(_tokenId: Uint256) -> (nft: NFT) {
    }
}
