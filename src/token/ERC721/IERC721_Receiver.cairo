%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC721_Receiver:
    func onERC721Received(
        _operator: felt, _from: felt, _tokenId: Uint256, data_len: felt, data: felt*) -> (selector: felt): 
    end
end
