%lang starknet
from starkware.cairo.common.uint256 import Uint256


@contract_interface
namespace IUniversalMetadata {
    func name() -> (res: felt) {
    }

    func symbol() -> (res: felt) {
    }
}
