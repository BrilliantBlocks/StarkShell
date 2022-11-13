%lang starknet
from starkware.cairo.common.uint256 import Uint256

from bootstrap.Structs import ClassHash

@contract_interface
namespace IBootstrapper {
    func deployRootDiamond(
        _class: ClassHash,
        _setZKLfun_selector: felt,
        _setZKLfun_compiled_len: felt,
        _setZKLfun_compiled: felt*,
        _mintContract_selector: felt,
        _mintContract_compiled_len: felt,
        _mintContract_compiled: felt*,
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
        _mintContract_selector: felt,
        _mintContract_hash: felt,
        _mintContract_compiled_len: felt,
        _mintContract_compiled: felt*,
    ) -> () {
    }
}
