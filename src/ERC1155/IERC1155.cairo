%lang starknet
from starkware.cairo.common.uint256 import Uint256


/// @selector 0x182d859c0807ba9db63baf8b9d9fdbfeb885d820be6e206b9dab626d995c433
@event
func TransferSingle(operator: felt, from_: felt, to: felt, id: Uint256, amount: Uint256) {
}

/// @selector 0x2563683c757f3abe19c4b7237e2285d8993417ddffe0b54a19eb212ea574b08
@event
func TransferBatch(operator: felt, from_: felt, to: felt, ids_len: felt, ids: Uint256*, amounts_len: felt, amounts: Uint256*) {
}

/// @selector 0x6ad9ed7b6318f1bcffefe19df9aeb40d22c36bed567e1925a5ccde0536edd
@event
func ApprovalForAll(owner: felt, operator: felt, approved: felt) {
}

struct TokenBatch {
    id: Uint256,
    amount: Uint256,
}

@contract_interface
namespace IERC1155 {
    /// @selector 0x2e4263afad30923c891518314c3c95dbe830a16874e8abc5777a9a20b54c76e
    func balanceOf(owner: felt, token_id: Uint256) -> (balance: Uint256) {
    }

    /// @selector 0x116d888b0a9ad3998fcf1cdb2711375c69ac1847e806a480e3585c3da18eac3
    func balanceOfBatch(owners_len: felt, owners: felt*, tokens_id_len: felt, tokens_id: Uint256*) -> (balances_len: felt, balances: Uint256*) {
    }
    /// @selector 0x21cdf9aedfed41bc4485ae779fda471feca12075d9127a0fc70ac6b3b3d9c30
    func isApprovedForAll(owner: felt, operator: felt) -> (bool: felt) {
    }

    /// @selector 0x3b77bb06507b9710290eb6316d99fc4137d455e978b1844e75af5b0f36f0379
    func setApprovalForAll(operator: felt, approved: felt) -> () {
    }

    /// @selector 0x19d59d013d4aa1a8b1ce4c8299086f070733b453c02d0dc46e735edc04d6444
    func safeTransferFrom(from_: felt, to: felt, token_id: Uint256, amount: Uint256) -> () {
    }

    /// @selector 0x23cc35d21c405aa7adf1f3afcf558aec0dbe6a45cade725420609aef87e9035
    func safeBatchTransferFrom(from_: felt, to: felt, tokens_id_len: felt, tokens_id: Uint256*, amounts_len: felt, amounts: Uint256*) -> () {
    }
}
