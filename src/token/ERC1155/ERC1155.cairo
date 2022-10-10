%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import (
    assert_nn_le,
    assert_not_equal,
    assert_not_zero,
    assert_le,
    assert_nn,
)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and

//from contracts.lib.Assertions import assert_only_diamond

const MASK = 2 ** 251 - 2 ** 128;


@event
func TransferSingle(operator: felt, from_: felt, to: felt, id: felt, amount: felt) {
}

@event
func TransferBatch(operator: felt, from_: felt, to: felt, ids: felt, amounts: felt) {
}

@event
func ApprovalForAll(owner: felt, operator: felt, approved: felt) {
}


// ToDo Find solution for caip-29 format
@event
func URI(endpoint: felt, id: felt) {
}

@storage_var
func balances(owner: felt, token_id: felt) -> (res: felt) {
}

@storage_var
func operator_approvals(owner: felt, operator: felt) -> (res: felt) {
}

@storage_var
func _uri(collectionId: felt) -> (res: felt) {
}



func _set_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    collectionId: felt, uri_: felt
) {
    let (old_uri) = _uri.read(collectionId);

    if (old_uri != uri_) {
        with_attr error_message("URI for existing collection ID cannot be changed.") {
            assert old_uri = 0;
        }
    }
    // Todo: too noisy event emissions. emits even if URI did not change.
    _uri.write(collectionId, uri_);
    URI.emit(uri_, collectionId);
    return ();
}


@external
func _mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, token_id: felt, amount: felt, collectionId: felt, uri_: felt
) -> () {
    //assert_only_diamond();

    with_attr error_message("Address cannot be zero.") {
        assert_not_zero(to);
    }
    with_attr error_message("Amount cannot be negative.") {
        assert_nn(amount);
    }
    let (res) = balances.read(owner=to, token_id=token_id);
    balances.write(to, token_id, res + amount);
    _set_uri(collectionId, uri_);
    return ();
}


@external
func _mint_batch{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt,
    tokens_id_len: felt,
    tokens_id: felt*,
    amounts_len: felt,
    amounts: felt*,
    collections_id_len: felt,
    collections_id: felt*,
    uris_len: felt,
    uris: felt*,
) -> () {
    //assert_only_diamond();

    with_attr error_message("Address cannot be zero.") {
        assert_not_zero(to);
    }
    with_attr error_message("Token id and amount array lenghts don't match.") {
        assert tokens_id_len = amounts_len;
    }

    if (tokens_id_len == 0) {
        return ();
    }

    _mint(to, tokens_id[0], amounts[0], collections_id[0], uris[0]);
    return _mint_batch(
        to=to,
        tokens_id_len=tokens_id_len - 1,
        tokens_id=tokens_id + 1,
        amounts_len=amounts_len - 1,
        amounts=amounts + 1,
        collections_id_len=collections_id_len - 1,
        collections_id=collections_id + 1,
        uris_len=uris_len - 1,
        uris=uris + 1,
    );
}

//
// Getters
//

// @view
// func uri{
//     syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
// }(tokenId: felt) -> (tokenUri: felt) {
//     let (collectionId) = bitwise_and(tokenId, MASK);
//     let (res) = _uri.read(collectionId);
//     return (res,);
// }


@view
func balanceOf{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owner: felt, token_id: felt
) -> (res: felt) {
    with_attr error_message("Address cannot be zero.") {
        assert_not_zero(owner);
    }
    let (res) = balances.read(owner=owner, token_id=token_id);
    return (res,);
}


@view
func balanceOfBatch{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owners_len: felt, owners: felt*, tokens_id_len: felt, tokens_id: felt*
) -> (res_len: felt, res: felt*) {
    with_attr error_message("Address and token id array lenghts don't match.") {
        assert owners_len = tokens_id_len;
    }
    alloc_locals;
    local max = owners_len;
    let (local ret_array: felt*) = alloc();
    local ret_index = 0;
    populate_balance_of_batch(owners, tokens_id, ret_array, ret_index, max);
    return (max, ret_array);
}


func populate_balance_of_batch{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owners: felt*, tokens_id: felt*, rett: felt*, ret_index: felt, max: felt
) {
    alloc_locals;
    if (ret_index == max) {
        return ();
    }
    let (local retval0: felt) = balances.read(owner=owners[0], token_id=tokens_id[0]);
    rett[0] = retval0;
    populate_balance_of_batch(owners + 1, tokens_id + 1, rett + 1, ret_index + 1, max);
    return ();
}

//
// Approvals
//

@view
func isApprovedForAll{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    account: felt, operator: felt
) -> (res: felt) {
    let (res) = operator_approvals.read(owner=account, operator=operator);
    return (res=res);
}


@external
func setApprovalForAll{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    operator: felt, approved: felt
) {
    let (account) = get_caller_address();
    with_attr error_message("You cannot set approval for yourself.") {
        assert_not_equal(account, operator);
    }
    // ensure approved is a boolean (0 or 1)
    with_attr error_message("Approval parameter is not a boolean.") {
        assert approved * (1 - approved) = 0;
    }
    operator_approvals.write(account, operator, approved);
    ApprovalForAll.emit(account, operator, approved);
    return ();
}

//
// Transfer from
//

@external
func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _from: felt, to: felt, token_id: felt, amount: felt
) {
    _assert_is_owner_or_approved(_from);
    _transfer_from(_from, to, token_id, amount);
    let (caller) = get_caller_address();
    TransferSingle.emit(caller, _from, to, token_id, amount);
    return ();
}


@external
func safeBatchTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _from: felt, to: felt, tokens_id_len: felt, tokens_id: felt*, amounts_len: felt, amounts: felt*
) {
    _assert_is_owner_or_approved(_from);
    _batch_transfer_from(_from, to, tokens_id_len, tokens_id, amounts_len, amounts);
    let (caller) = get_caller_address();
    TransferBatch.emit(caller, _from, to, tokens_id_len, amounts_len);
    return ();
}


func _transfer_from{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    sender: felt, recipient: felt, token_id: felt, amount: felt
) {
    // check recipient != 0
    with_attr error_message("Recipient address cannot be zero.") {
        assert_not_zero(recipient);
    }

    // validate sender has enough funds
    let (sender_balance) = balances.read(owner=sender, token_id=token_id);
    with_attr error_message("Sender has not enough funds.") {
        assert_nn_le(amount, sender_balance);
    }

    // substract from sender
    balances.write(sender, token_id, sender_balance - amount);

    // add to recipient
    let (res) = balances.read(owner=recipient, token_id=token_id);
    balances.write(recipient, token_id, res + amount);
    return ();
}


func _batch_transfer_from{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _from: felt, to: felt, tokens_id_len: felt, tokens_id: felt*, amounts_len: felt, amounts: felt*
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
    return _batch_transfer_from(
        _from=_from,
        to=to,
        tokens_id_len=tokens_id_len - 1,
        tokens_id=tokens_id + 1,
        amounts_len=amounts_len - 1,
        amounts=amounts + 1,
    );
}


// function to test ERC1155 requirement : require(from == _msgSender() || isApprovedForAll(from, _msgSender())
func _assert_is_owner_or_approved{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    address: felt
) {
    let (caller) = get_caller_address();

    if (caller == address) {
        return ();
    }

    let (operator_is_approved) = isApprovedForAll(account=address, operator=caller);
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
    //assert_only_diamond();

    with_attr error_message("Address cannot be zero") {
        assert_not_zero(_from);
    }
    with_attr error_message("Amount cannot be negative.") {
        assert_nn(amount);
    }

    let (from_balance) = balances.read(_from, token_id);
    with_attr error_message("Address has not enough funds.") {
        assert_le(amount, from_balance);
    }
    balances.write(_from, token_id, from_balance - amount);
    return ();
}


@external
func _burn_batch{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _from: felt, tokens_id_len: felt, tokens_id: felt*, amounts_len: felt, amounts: felt*
) {
    //assert_only_diamond();

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
    return _burn_batch(
        _from=_from,
        tokens_id_len=tokens_id_len - 1,
        tokens_id=tokens_id + 1,
        amounts_len=amounts_len - 1,
        amounts=amounts + 1,
    );
}
