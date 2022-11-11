%lang starknet
from starkware.cairo.common.uint256 import Uint256

from src.ERC2535.Structs import ClassHash

@contract_interface
namespace IRootDiamondFactory {
    func deployRootDiamond(
        _class: ClassHash,
        _setZKLfun_selector: felt,
        _setZKLfun_compiled_len: felt,
        _setZKLfun_compiled: felt*,
    ) -> (rootAddress: felt) {
    }

    func init(
        _owner: felt,
        _tokenId: Uint256,
        _class: ClassHash,
        _setZKLfun_selector: felt,
        _setZKLfun_hash: felt,
        _setZKLfun_compiled_len: felt,
        _setZKLfun_compiled: felt*,
    ) -> () {
    }
}