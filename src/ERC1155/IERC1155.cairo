%lang starknet

from starkware.cairo.common.uint256 import Uint256


@contract_interface
namespace IERC1155 {

    func balanceOf(owner: felt, token_id: Uint256) -> (balance: Uint256) {
    }

    func balanceOfBatch(owners_len: felt, owners: felt*, tokens_id_len: felt, tokens_id: Uint256*) -> (balances_len: felt, balances: Uint256*) {
    }

    func isApprovedForAll(owner: felt, operator: felt) -> (bool: felt) {
    }

    func setApprovalForAll(operator: felt, approved: felt) -> () {
    }

    func safeTransferFrom(from_: felt, to: felt, token_id: Uint256, amount: Uint256) -> () {
    }

    func safeBatchTransferFrom(from_: felt, to: felt, tokens_id_len: felt, tokens_id: Uint256*, amounts_len: felt, amounts: Uint256*) -> () {
    }

    func mint(to: felt, token_id: Uint256, amount: Uint256) -> () {
    }

    func mint_batch(to: felt, tokens_id_len: felt, tokens_id: Uint256*, amounts_len: felt, amounts: Uint256*) -> () {
    }

    func burn(from_: felt, token_id: Uint256, amount: Uint256) -> () {
    }

    func burn_batch(from_: felt, tokens_id_len: felt, tokens_id: Uint256*, amounts_len: felt, amounts: Uint256*) -> () {
    }
}