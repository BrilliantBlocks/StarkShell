%lang starknet

from starkware.cairo.common.uint256 import Uint256


@contract_interface
namespace IERC20 {
    func name() -> (res: felt) {
    }

    func symbol() -> (res: felt) {
    }

    func decimals() -> (res: felt) {
    }

    func totalSupply() -> (res: Uint256) {
    }

    func balanceOf(owner: felt) -> (balance: Uint256) {
    }

    func allowance(owner: felt, spender: felt) -> (amount: Uint256) {
    }

    func transfer(recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func transferFrom(sender: felt, recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func approve(spender: felt, amount: Uint256) -> (success: felt) {
    }
}