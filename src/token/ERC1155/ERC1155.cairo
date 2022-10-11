%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import (
    assert_nn_le,
    assert_not_equal,
    assert_not_zero,
    assert_le,
    assert_nn,
)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_le
from starkware.cairo.common.memcpy import memcpy

from src.token.ERC721.util.ShortString import uint256_to_ss
from src.token.ERC721.util.Safemath import SafeUint256


@event
func TransferSingle(operator: felt, from_: felt, to: felt, id: Uint256, amount: Uint256) {
}

@event
func TransferBatch(operator: felt, from_: felt, to: felt, ids_len: felt, ids: Uint256*, amounts_len: felt, amounts: Uint256*) {
}

@event
func ApprovalForAll(owner: felt, operator: felt, approved: felt) {
}


@storage_var
func _balances(owner: felt, token_id: Uint256) -> (balance: Uint256) {
}

@storage_var
func _operator_approvals(owner: felt, operator: felt) -> (res: felt) {
}



@external
func _mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, token_id: Uint256, amount: Uint256
) -> () {

    with_attr error_message("Address cannot be zero.") {
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


@external
func _mint_batch{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokens_id_len: felt, tokens_id: Uint256*, amounts_len: felt, amounts: Uint256*
) -> () {

    with_attr error_message("Address cannot be zero.") {
        assert_not_zero(to);
    }
    with_attr error_message("Token id and amount array lenghts don't match.") {
        assert tokens_id_len = amounts_len;
    }

    if (tokens_id_len == 0) {
        return ();
    }

    _mint(to, tokens_id[0], amounts[0]);
    return _mint_batch(to, tokens_id_len - 1, tokens_id + Uint256.SIZE, amounts_len - 1, amounts + Uint256.SIZE);
}

//
// Getters
//

@view
func balanceOf{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owner: felt, token_id: Uint256
) -> (balance: Uint256) {
    with_attr error_message("Address cannot be zero.") {
        assert_not_zero(owner);
    }
    let balance = _balances.read(owner, token_id);
    return balance;
}


@view
func balanceOfBatch{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
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
    let (balance) = _balances.read(owners[0], tokens_id[0]);
    assert balance_array[0] = balance;
    populate_balance_of_batch(owners + 1, tokens_id + Uint256.SIZE, balance_array + Uint256.SIZE, balance_array_len, current_id + 1);
    return ();
}

//
// Approvals
//

@view
func isApprovedForAll{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owner: felt, operator: felt
) -> (bool: felt) {
    let (approved) = _operator_approvals.read(owner, operator);
    return (approved,);
}


@external
func setApprovalForAll{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    operator: felt, approved: felt
) {
    let (caller) = get_caller_address();
    with_attr error_message("You cannot set approval for yourself.") {
        assert_not_equal(caller, operator);
    }
    with_attr error_message("Approval parameter is not a boolean.") {
        assert approved * (1 - approved) = 0;
    }

    _operator_approvals.write(caller, operator, approved);
    ApprovalForAll.emit(caller, operator, approved);
    return ();
}

//
// Transfer from
//

@external
func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _from: felt, to: felt, token_id: Uint256, amount: Uint256
) {
    assert_is_owner_or_approved(_from);
    _transfer_from(_from, to, token_id, amount);
    
    let (caller) = get_caller_address();
    TransferSingle.emit(caller, _from, to, token_id, amount);
    return ();
}


@external
func safeBatchTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _from: felt, to: felt, tokens_id_len: felt, tokens_id: Uint256*, amounts_len: felt, amounts: Uint256*
) {
    alloc_locals;
    assert_is_owner_or_approved(_from);
    _batch_transfer_from(_from, to, tokens_id_len, tokens_id, amounts_len, amounts);
    
    let (caller) = get_caller_address();
    TransferBatch.emit(caller, _from, to, tokens_id_len, tokens_id, amounts_len, amounts);
    return ();
}


func _transfer_from{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    sender: felt, recipient: felt, token_id: Uint256, amount: Uint256
) {
    with_attr error_message("Recipient address cannot be zero.") {
        assert_not_zero(recipient);
    }

    let (sender_balance) = _balances.read(sender, token_id);
    let (sufficient_balance) = uint256_le(amount, sender_balance);
    with_attr error_message("Sender has not enough funds.") {
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
    _from: felt, to: felt, tokens_id_len: felt, tokens_id: Uint256*, amounts_len: felt, amounts: Uint256*
) {
    with_attr error_message("Token id and amount array lenghts don't match.") {
        assert tokens_id_len = amounts_len;
    }
    with_attr error_message("Recipient address cannot be zero.") {
        assert_not_zero(to);
    }

    if (tokens_id_len == 0) {
        return ();
    }
    _transfer_from(_from, to, [tokens_id], [amounts]);

    return _batch_transfer_from(_from, to, tokens_id_len - 1, tokens_id + 1, amounts_len - 1, amounts + 1);
}


// function to test ERC1155 requirement : require(from == _msgSender() || isApprovedForAll(from, _msgSender())
func assert_is_owner_or_approved{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    address: felt
) {
    let (caller) = get_caller_address();

    if (caller == address) {
        return ();
    }

    let (operator_is_approved) = isApprovedForAll(address, caller);
    with_attr error_message("You are not approved to perform this action.") {
        assert operator_is_approved = 1;
    }
    return ();
}

//
// Burn
//

@external
func _burn{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _from: felt, token_id: felt, amount: felt
) {

    with_attr error_message("Address cannot be zero") {
        assert_not_zero(_from);
    }
    with_attr error_message("Amount cannot be negative.") {
        assert_nn(amount);
    }

    let (owner_balance) = _balances.read(_from, token_id);
    with_attr error_message("Address has not enough funds.") {
        assert_le(amount, owner_balance);
    }
    _balances.write(_from, token_id, owner_balance - amount);
    return ();
}


@external
func _burn_batch{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _from: felt, tokens_id_len: felt, tokens_id: felt*, amounts_len: felt, amounts: felt*
) {

    with_attr error_message("Address cannot be zero") {
        assert_not_zero(_from);
    }

    with_attr error_message("Token id and amount array lenghts don't match.") {
        assert tokens_id_len = amounts_len;
    }
    if (tokens_id_len == 0) {
        return ();
    }
    _burn(_from, [tokens_id], [amounts]);

    return _burn_batch(_from, tokens_id_len - 1, tokens_id + 1, amounts_len - 1, amounts + 1);
}
