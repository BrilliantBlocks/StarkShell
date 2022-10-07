%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.uint256 import Uint256, uint256_check, assert_uint256_le, uint256_add, uint256_sub, uint256_eq
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.registers import get_label_location
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp

from src.constants import FUNCTION_SELECTORS


@event
func Transfer(from_: felt, to: felt, id: Uint256, value: Uint256) {
}

@event
func Approval(owner: felt, spender: felt, id: Uint256, value: Uint256) {
}

@event
func TokenAddition(parent_token: felt, parent_token_id: Uint256, id: Uint256, total_supply: Uint256) {
}


@storage_var
func _balances(owner: felt, id: Uint256) -> (res: Uint256) {
}

@storage_var
func _token_registry(id: Uint256) -> (res: (parent_nft_contract_address: felt, parent_nft_token_id: Uint256, total_supply: Uint256)) {
}

@storage_var
func _allowances(owner: felt, spender: felt, id: Uint256) -> (amount: Uint256) {
}


@external
func setParentNFT{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    parent_nft_contract_address: felt, parent_nft_token_id: Uint256, total_supply: Uint256
) -> () {
    alloc_locals;

    with_attr error_message("Parent contract address must not be the zero address") {
        assert_not_zero(parent_nft_contract_address);
    }

    let (is_registered) = check_if_registered(parent_nft_contract_address, parent_nft_token_id, Uint256(0,0));
    with_attr error_message("NFT is already registered") {
        assert is_registered = FALSE;
    }

    // Add assertions

    let (next_free_id) = get_next_free_id(0);
    
    _token_registry.write(next_free_id, (parent_nft_contract_address, parent_nft_token_id, total_supply));

    return ();
}


func check_if_registered{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    parent_nft_contract_address: felt, parent_nft_token_id: Uint256, current_id: Uint256
) -> (bool: felt) {
    alloc_locals;
    let (entry) = _token_registry.read(current_id);

    if (entry[0] == 0) {
        return (FALSE,);
    }

    if (entry[0] == parent_nft_contract_address) {
        let (token_is_equal) = uint256_eq(entry[1], parent_nft_token_id);
        if (token_is_equal == TRUE) {
            return (TRUE,);
        }
    }

    let (next_id,_) = uint256_add(current_id, Uint256(1,0));
    return check_if_registered(parent_nft_contract_address, parent_nft_token_id, next_id);
}


func get_next_free_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    current_id: felt
) -> (next_free_id: Uint256) {
    let (entry) = _token_registry.read(current_id);

    if (entry[0] == 0) {
        return Uint256(0,0);
    }

    let (sum) = get_next_free_id(current_id + 1);
    return (sum + 1,);
}


@external
func totalSupply{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    id: Uint256
) -> (res: Uint256) {
    
    with_attr error_message("Token ID is not a valid Uint256") {
        uint256_check(id);
    }
    
    let (entry) = _token_registry.read(id);
    let (total_supply) = entry[2];

    return total_supply;
}


@external
func balanceOf{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owner: felt, id: Uint256
) -> (res: Uint256) {
    
    with_attr error_message("Token ID is not a valid Uint256") {
        uint256_check(id);
    }

    with_attr error_message("Owner address must not be the zero address") {
        assert_not_zero(owner);
    }
    
    let balance = _balances.read(owner, id);

    return balance;
}


@external
func allowance{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owner: felt, spender: felt, id: Uint256
) -> (amount: Uint256) {
    
    with_attr error_message("Token ID is not a valid Uint256") {
        uint256_check(id);
    }

    with_attr error_message("Owner address must not be the zero address") {
        assert_not_zero(owner);
    }

    with_attr error_message("Owner address must not be the zero address") {
        assert_not_zero(spender);
    }
    
    let allowance = _allowances.read(owner, spender, id);

    return allowance;
}


@external
func isRegistered{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    parent_nft_contract_address: felt, parent_nft_token_id: Uint256
) -> (bool: felt) {
    
    with_attr error_message("Token ID is not a valid Uint256") {
        uint256_check(parent_nft_token_id);
    }

    with_attr error_message("Owner address must not be the zero address") {
        assert_not_zero(parent_nft_contract_address);
    }

    let (is_registered) = check_if_registered(parent_nft_contract_address, parent_nft_token_id, Uint256(0,0));

    return is_registered;
}



@external
func transfer{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, id: Uint256, value: Uint256
) -> (bool: felt) {
    
    with_attr error_message("Receiver must not be the zero address") {
        assert_not_zero(to);
    }
    
    let (caller) = get_caller_address();
    let (caller_balance) = _balances.read(caller, id);

    with_attr error_message("Token balance is unsufficient") {
        assert_uint256_le(value, caller_balance);
    }

    //Check if ID registered

    _transfer(caller, to, id, value);

    return (TRUE,);
}


@external
func transferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, id: Uint256, value: Uint256
) -> (bool: felt) {
    
    with_attr error_message("Receiver must not be the zero address") {
        assert_not_zero(to);
    }


    
    let (sender_balance) = _balances.read(from_, id);
    with_attr error_message("Token balance is unsufficient") {
        assert_uint256_le(value, sender_balance);
    }

    //Check if ID registered

    _transfer(from_, to, id, value);

    return (TRUE,);
}


func _transfer{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, id: Uint256, value: Uint256
) -> () {

    let (sender_balance) = _balances.read(from_, id);
    let (recipient_balance) = _balances.read(to, id);
    let (new_sender_balance) = uint256_sub(sender_balance, value);
    let (new_recipient_balance, _) = uint256_add(recipient_balance, value);

    _balances.write(from_, id, new_sender_balance);
    _balances.write(to, id, new_recipient_balance);

    return ();
}








