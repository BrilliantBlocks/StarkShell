%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_equal, assert_not_zero
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import (
    Uint256, 
    uint256_check, 
    uint256_le
)
from starkware.cairo.common.memcpy import memcpy

from lib.cairo_contracts.src.openzeppelin.security.safemath.library import SafeUint256

from src.ERC1155.IERC1155 import TransferSingle, TransferBatch, ApprovalForAll


@storage_var
func _balances(owner: felt, token_id: Uint256) -> (balance: Uint256) {
}

@storage_var
func _operator_approvals(owner: felt, operator: felt) -> (res: felt) {
}


namespace ERC1155 {

    func balance_of{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        owner: felt, token_id: Uint256
    ) -> (balance: Uint256) {
        with_attr error_message("Owner address must not be zero") {
            assert_not_zero(owner);
        }
        with_attr error_message("Token ID is not a valid Uint256") {
            uint256_check(token_id);
        }
        let balance = _balances.read(owner, token_id);
        return balance;
    }


    func balance_of_batch{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        owners_len: felt, owners: felt*, tokens_id_len: felt, tokens_id: Uint256*
    ) -> (balances_len: felt, balances: Uint256*) {
        alloc_locals;
        with_attr error_message("Owners array must not be empty") {
            assert_not_zero(owners_len);
        }
        with_attr error_message("Address and token id array lenghts don't match.") {
            assert owners_len = tokens_id_len;
        }

        let (balance_array: Uint256*) = alloc();
        local balance_array_len = owners_len;
        tempvar current_id = 0;

        populate_balance_of_batch(owners, tokens_id, balance_array, balance_array_len, current_id);
        return (balance_array_len, balance_array);
    }


    func populate_balance_of_batch{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        owners: felt*, tokens_id: Uint256*, balance_array: Uint256*, balance_array_len: felt, current_id: felt
    ) {
        alloc_locals;
        if (current_id == balance_array_len) {
            return ();
        }
        let (balance) = balance_of(owners[0], tokens_id[0]);
        assert balance_array[0] = balance;
        populate_balance_of_batch(owners + 1, tokens_id + Uint256.SIZE, balance_array + Uint256.SIZE, balance_array_len, current_id + 1);
        return ();
    }


    func is_approved_for_all{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        owner: felt, operator: felt
    ) -> (bool: felt) {
        let (approved) = _operator_approvals.read(owner, operator);
        return (approved,);
    }


    func set_approval_for_all{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        operator: felt, approved: felt
    ) {
        with_attr error_message("Operator address must not be zero") {
            assert_not_zero(operator);
        }
        let (caller) = get_caller_address();
        with_attr error_message("You must not set approval for yourself") {
            assert_not_equal(caller, operator);
        }
        with_attr error_message("Approval parameter must be a boolean") {
            assert approved * (1 - approved) = 0;
        }

        _operator_approvals.write(caller, operator, approved);
        ApprovalForAll.emit(caller, operator, approved);
        return ();
    }


    func safe_transfer_from{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        from_: felt, to: felt, token_id: Uint256, amount: Uint256
    ) {
        with_attr error_message("Sender address must not be zero") {
            assert_not_zero(from_);
        }
        with_attr error_message("Recipient address must not be zero") {
            assert_not_zero(to);
        }
        assert_is_owner_or_approved(from_);
        _transfer_from(from_, to, token_id, amount);
        
        let (caller) = get_caller_address();
        TransferSingle.emit(caller, from_, to, token_id, amount);
        return ();
    }


    func safe_batch_transfer_from{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        from_: felt, to: felt, tokens_id_len: felt, tokens_id: Uint256*, amounts_len: felt, amounts: Uint256*
    ) {
        alloc_locals;
        with_attr error_message("Sender address must not be zero") {
            assert_not_zero(from_);
        }
        with_attr error_message("Recipient address must not be zero") {
            assert_not_zero(to);
        }
        assert_is_owner_or_approved(from_);
        _batch_transfer_from(from_, to, tokens_id_len, tokens_id, amounts_len, amounts);
        
        let (caller) = get_caller_address();
        TransferBatch.emit(caller, from_, to, tokens_id_len, tokens_id, amounts_len, amounts);
        return ();
    }


    func _transfer_from{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        sender: felt, recipient: felt, token_id: Uint256, amount: Uint256
    ) {
        with_attr error_message("Token ID is not a valid Uint256") {
            uint256_check(token_id);
        }
        with_attr error_message("Amount is not a valid Uint256") {
            uint256_check(amount);
        }
        let (sender_balance) = _balances.read(sender, token_id);
        let (sufficient_balance) = uint256_le(amount, sender_balance);
        with_attr error_message("Sender has not enough funds") {
            assert sufficient_balance = TRUE;
        }

        let (new_sender_balance) = SafeUint256.sub_le(sender_balance, amount);
        _balances.write(sender, token_id, new_sender_balance);

        let (recipient_balance) = _balances.read(recipient, token_id);
        let (new_recipient_balance) = SafeUint256.add(recipient_balance, amount);
        _balances.write(recipient, token_id, new_recipient_balance);
        return ();
    }


    func _batch_transfer_from{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        from_: felt, to: felt, tokens_id_len: felt, tokens_id: Uint256*, amounts_len: felt, amounts: Uint256*
    ) {
        with_attr error_message("Token id and amount array lenghts don't match") {
            assert tokens_id_len = amounts_len;
        }

        if (tokens_id_len == 0) {
            return ();
        }
        _transfer_from(from_, to, tokens_id[0], amounts[0]);

        return _batch_transfer_from(from_, to, tokens_id_len - 1, tokens_id + Uint256.SIZE, amounts_len - 1, amounts + Uint256.SIZE);
    }


    func assert_is_owner_or_approved{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        address: felt
    ) {
        let (caller) = get_caller_address();

        if (caller == address) {
            return ();
        }

        let (operator_is_approved) = _operator_approvals.read(address, caller);
        with_attr error_message("You are not approved to perform this action") {
            assert operator_is_approved = TRUE;
        }
        return ();
    }


    func _mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        to: felt, token_id: Uint256, amount: Uint256
    ) -> () {
        with_attr error_message("Address must not be zero") {
            assert_not_zero(to);
        }
        with_attr error_message("Token ID is not a valid Uint256") {
            uint256_check(token_id);
        }
        with_attr error_message("Amount is not a valid Uint256") {
            uint256_check(amount);
        }

        let (balance) = _balances.read(to, token_id);
        let (new_balance) = SafeUint256.add(balance, amount);
        _balances.write(to, token_id, new_balance);
        return ();
    }


    func _mint_batch{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        to: felt, tokens_id_len: felt, tokens_id: Uint256*, amounts_len: felt, amounts: Uint256*
    ) -> () {
        with_attr error_message("Token id and amount array lenghts don't match") {
            assert tokens_id_len = amounts_len;
        }

        if (tokens_id_len == 0) {
            return ();
        }

        _mint(to, tokens_id[0], amounts[0]);
        return _mint_batch(to, tokens_id_len - 1, tokens_id + Uint256.SIZE, amounts_len - 1, amounts + Uint256.SIZE);
    }


    func _burn{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        from_: felt, token_id: Uint256, amount: Uint256
    ) {
        with_attr error_message("Owner address must not be zero") {
            assert_not_zero(from_);
        }
        with_attr error_message("Token ID is not a valid Uint256") {
            uint256_check(token_id);
        }
        with_attr error_message("Amount is not a valid Uint256") {
            uint256_check(amount);
        }

        let (owner_balance) = _balances.read(from_, token_id);
        let (sufficient_balance) = uint256_le(amount, owner_balance);
        with_attr error_message("Owner has not enough funds") {
            assert sufficient_balance = TRUE;
        }
        let (new_owner_balance) = SafeUint256.sub_le(owner_balance, amount);

        _balances.write(from_, token_id, new_owner_balance);
        return ();
    }


    func _burn_batch{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        from_: felt, tokens_id_len: felt, tokens_id: Uint256*, amounts_len: felt, amounts: Uint256*
    ) {
        with_attr error_message("Token id and amount array lenghts don't match") {
            assert tokens_id_len = amounts_len;
        }
        if (tokens_id_len == 0) {
            return ();
        }
        _burn(from_, tokens_id[0], amounts[0]);

        return _burn_batch(from_, tokens_id_len - 1, tokens_id + Uint256.SIZE, amounts_len - 1, amounts + Uint256.SIZE);
    }
}
