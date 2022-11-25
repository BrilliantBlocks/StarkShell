%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_check,
    assert_uint256_le,
    uint256_add,
    uint256_sub,
    uint256_eq,
)
from starkware.cairo.common.math import assert_not_zero, assert_not_equal
from starkware.cairo.common.registers import get_label_location
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from src.zkode.ERC721.IERC721 import IERC721
from src.zkode.constants import FUNCTION_SELECTORS, IERC4675_ID

@event
func Transfer(from_: felt, to: felt, id: Uint256, amount: Uint256) {
}

@event
func Approval(owner: felt, spender: felt, id: Uint256, amount: Uint256) {
}

@event
func TokenAddition(
    parent_token: felt, parent_token_id: Uint256, id: Uint256, total_supply: Uint256
) {
}

@storage_var
func _admin() -> (address: felt) {
}

@storage_var
func _balances(owner: felt, id: Uint256) -> (res: Uint256) {
}

@storage_var
func _token_registry(id: Uint256) -> (
    res: (parent_nft_contract_address: felt, parent_nft_token_id: Uint256, total_supply: Uint256)
) {
}

@storage_var
func _allowances(owner: felt, spender: felt, id: Uint256) -> (amount: Uint256) {
}

@external
func setParentNFT{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    parent_nft_contract_address: felt, parent_nft_token_id: Uint256, total_supply: Uint256
) -> () {
    assert_only_admin();

    with_attr error_message("Parent contract address must not be the zero address") {
        assert_not_zero(parent_nft_contract_address);
    }

    with_attr error_message("Parent NFT token ID is not a valid Uint256") {
        uint256_check(parent_nft_token_id);
    }

    with_attr error_message("Total supply is not a valid Uint256") {
        uint256_check(total_supply);
    }

    let (is_registered) = check_if_registered(
        parent_nft_contract_address, parent_nft_token_id, Uint256(0, 0)
    );
    with_attr error_message("NFT is already registered") {
        assert is_registered = FALSE;
    }

    let (contract_address) = get_contract_address();
    let (nft_owner) = IERC721.ownerOf(parent_nft_contract_address, parent_nft_token_id);
    with_attr error_message("Contract must be NFT owner") {
        assert contract_address = nft_owner;
    }

    let (next_free_id) = get_next_free_id(Uint256(0, 0));

    _token_registry.write(
        next_free_id, (parent_nft_contract_address, parent_nft_token_id, total_supply)
    );

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

    let (token_is_equal) = uint256_eq(entry[1], parent_nft_token_id);
    if (entry[0] == parent_nft_contract_address and token_is_equal == TRUE) {
        return (TRUE,);
    }

    let (next_id, _) = uint256_add(current_id, Uint256(1, 0));
    return check_if_registered(parent_nft_contract_address, parent_nft_token_id, next_id);
}

func get_next_free_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    current_id: Uint256
) -> (next_free_id: Uint256) {
    let (entry) = _token_registry.read(current_id);
    let zero_id = Uint256(0, 0);

    if (entry[0] == 0) {
        return (zero_id,);
    }

    let (next_id, _) = uint256_add(current_id, Uint256(1, 0));
    let (sum) = get_next_free_id(next_id);
    let (sum_ret, _) = uint256_add(sum, Uint256(1, 0));
    return (sum_ret,);
}

@view
func totalSupply{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(id: Uint256) -> (
    res: Uint256
) {
    alloc_locals;
    with_attr error_message("Token ID is not a valid Uint256") {
        uint256_check(id);
    }

    let (entry) = _token_registry.read(id);
    local total_supply: Uint256 = entry[2];

    return (total_supply,);
}

@view
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
func approve{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    spender: felt, id: Uint256, amount: Uint256
) -> (bool: felt) {
    with_attr error_message("Token ID is not a valid Uint256") {
        uint256_check(id);
    }

    with_attr error_message("Token ID is not a valid Uint256") {
        uint256_check(amount);
    }

    with_attr error_message("Owner address must not be the zero address") {
        assert_not_zero(spender);
    }

    let (caller) = get_caller_address();
    let (caller_balance) = _balances.read(caller, id);

    with_attr error_message("Token balance is unsufficient") {
        assert_uint256_le(amount, caller_balance);
    }

    _allowances.write(caller, spender, id, amount);
    Approval.emit(caller, spender, id, amount);

    return (TRUE,);
}

@view
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

@view
func isRegistered{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    parent_nft_contract_address: felt, parent_nft_token_id: Uint256
) -> (bool: felt) {
    with_attr error_message("Token ID is not a valid Uint256") {
        uint256_check(parent_nft_token_id);
    }

    with_attr error_message("Owner address must not be the zero address") {
        assert_not_zero(parent_nft_contract_address);
    }

    let (is_registered) = check_if_registered(
        parent_nft_contract_address, parent_nft_token_id, Uint256(0, 0)
    );

    return (is_registered,);
}

@external
func transfer{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, id: Uint256, amount: Uint256
) -> (bool: felt) {
    with_attr error_message("Receiver must not be the zero address") {
        assert_not_zero(to);
    }

    with_attr error_message("Token ID is not a valid Uint256") {
        uint256_check(id);
    }

    with_attr error_message("Amount is not a valid Uint256") {
        uint256_check(amount);
    }

    let (entry) = _token_registry.read(id);
    with_attr error_message("NFT is not registered") {
        assert_not_zero(entry[0]);
    }

    let (caller) = get_caller_address();
    let (caller_balance) = _balances.read(caller, id);

    with_attr error_message("Token balance is unsufficient") {
        assert_uint256_le(amount, caller_balance);
    }

    _transfer(caller, to, id, amount);

    return (TRUE,);
}

@external
func transferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, id: Uint256, amount: Uint256
) -> (bool: felt) {
    let (caller) = get_caller_address();
    with_attr error_message("Use transfer function to transfer funds from your own address") {
        assert_not_equal(from_, caller);
    }

    with_attr error_message("Sender must not be the zero address") {
        assert_not_zero(from_);
    }

    with_attr error_message("Receiver must not be the zero address") {
        assert_not_zero(to);
    }

    with_attr error_message("Token ID is not a valid Uint256") {
        uint256_check(id);
    }

    with_attr error_message("Amount is not a valid Uint256") {
        uint256_check(amount);
    }

    let (entry) = _token_registry.read(id);
    with_attr error_message("NFT is not registered") {
        assert_not_zero(entry[0]);
    }

    _spend_allowance(from_, caller, id, amount);

    _transfer(from_, to, id, amount);

    return (TRUE,);
}

func _transfer{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, id: Uint256, amount: Uint256
) -> () {
    let (sender_balance) = _balances.read(from_, id);
    let (recipient_balance) = _balances.read(to, id);
    let (new_sender_balance) = uint256_sub(sender_balance, amount);
    let (new_recipient_balance, _) = uint256_add(recipient_balance, amount);

    _balances.write(from_, id, new_sender_balance);
    _balances.write(to, id, new_recipient_balance);

    return ();
}

func _spend_allowance{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owner: felt, spender: felt, id: Uint256, amount: Uint256
) -> () {
    let (allowance) = _allowances.read(owner, spender, id);
    with_attr error_message("Allowance is unsufficient") {
        assert_uint256_le(amount, allowance);
    }

    let (new_allowance) = uint256_sub(allowance, amount);
    _allowances.write(owner, spender, id, new_allowance);

    return ();
}

func assert_only_admin{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> () {
    let (admin) = _admin.read();
    let (caller) = get_caller_address();
    with_attr error_message("You must be the admin to call this function") {
        assert caller = admin;
    }

    return ();
}

@external
func __init_facet__{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    admin_address: felt
) -> () {
    _admin.write(admin_address);

    return ();
}

@view
func __pub_func__() -> (res_len: felt, res: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (res_len=8, res=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.ERC4675.setParentNFT;
    dw FUNCTION_SELECTORS.ERC4675.totalSupply;
    dw FUNCTION_SELECTORS.ERC4675.balanceOf;
    dw FUNCTION_SELECTORS.ERC4675.approve;
    dw FUNCTION_SELECTORS.ERC4675.allowance;
    dw FUNCTION_SELECTORS.ERC4675.isRegistered;
    dw FUNCTION_SELECTORS.ERC4675.transfer;
    dw FUNCTION_SELECTORS.ERC4675.transferFrom;
}

// @dev Support ERC-165
// @param interface_id
// @return success (0 or 1)
@view
func __supports_interface__(_interface_id: felt) -> (success: felt) {
    if (_interface_id == IERC4675_ID) {
        return (TRUE,);
    }

    return (FALSE,);
}
