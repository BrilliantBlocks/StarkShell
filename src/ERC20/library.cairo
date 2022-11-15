%lang starknet

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_le
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_eq, uint256_not

from lib.cairo_contracts.src.openzeppelin.security.safemath.library import SafeUint256
from lib.cairo_contracts.src.openzeppelin.utils.constants.library import UINT8_MAX

@event
func Transfer(from_: felt, to: felt, amount: Uint256) {
}

@event
func Approval(owner: felt, spender: felt, amount: Uint256) {
}

@storage_var
func _name() -> (res: felt) {
}

@storage_var
func _symbol() -> (res: felt) {
}

@storage_var
func _decimals() -> (res: felt) {
}

@storage_var
func _total_supply() -> (res: Uint256) {
}

@storage_var
func _balances(owner: felt) -> (balance: Uint256) {
}

@storage_var
func _allowances(owner: felt, spender: felt) -> (amount: Uint256) {
}

namespace ERC20 {
    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        name: felt, symbol: felt, decimals: felt
    ) {
        _name.write(name);
        _symbol.write(symbol);
        with_attr error_message("Decimals exceed 256") {
            assert_le(decimals, UINT8_MAX);
        }
        _decimals.write(decimals);
        return ();
    }

    func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
        let (name) = _name.read();
        return (name,);
    }

    func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        symbol: felt
    ) {
        let (symbol) = _symbol.read();
        return (symbol,);
    }

    func total_supply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        total_supply: Uint256
    ) {
        let (total_supply) = _total_supply.read();
        return (total_supply,);
    }

    func decimals{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        decimals: felt
    ) {
        let (decimals) = _decimals.read();
        return (decimals,);
    }

    func balance_of{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner: felt
    ) -> (balance: Uint256) {
        let (balance) = _balances.read(owner);
        return (balance,);
    }

    func allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner: felt, spender: felt
    ) -> (amount: Uint256) {
        let (allowance) = _allowances.read(owner, spender);
        return (allowance,);
    }

    func transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        recipient: felt, amount: Uint256
    ) -> (success: felt) {
        let (sender) = get_caller_address();
        _transfer(sender, recipient, amount);
        return (TRUE,);
    }

    func transfer_from{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        sender: felt, recipient: felt, amount: Uint256
    ) -> (success: felt) {
        let (caller) = get_caller_address();
        _spend_allowance(sender, caller, amount);
        _transfer(sender, recipient, amount);
        return (TRUE,);
    }

    func approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        spender: felt, amount: Uint256
    ) -> (success: felt) {
        with_attr error_message("Amount is not a valid Uint256") {
            uint256_check(amount);
        }

        let (caller) = get_caller_address();
        _approve(caller, spender, amount);
        return (TRUE,);
    }

    func increase_allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        spender: felt, added_amount: Uint256
    ) -> (success: felt) {
        with_attr error("Added amount is not a valid Uint256") {
            uint256_check(added_amount);
        }

        let (caller) = get_caller_address();
        let (current_allowance) = _allowances.read(caller, spender);

        with_attr error_message("Allowance overflow") {
            let (new_allowance) = SafeUint256.add(current_allowance, added_amount);
        }

        _approve(caller, spender, new_allowance);
        return (TRUE,);
    }

    func decrease_allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        spender: felt, subtracted_amount: Uint256
    ) -> (success: felt) {
        alloc_locals;
        with_attr error_message("Subtracted amount is not a valid Uint256") {
            uint256_check(subtracted_amount);
        }

        let (caller) = get_caller_address();
        let (current_allowance) = _allowances.read(caller, spender);

        with_attr error_message("Allowance must not be below zero") {
            let (new_allowance) = SafeUint256.sub_le(current_allowance, subtracted_amount);
        }

        _approve(caller, spender, new_allowance);
        return (TRUE,);
    }

    //
    // Internal
    //

    func _mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        recipient: felt, amount: Uint256
    ) -> () {
        with_attr error_message("Amount is not a valid Uint256") {
            uint256_check(amount);
        }

        with_attr error_message("Recipient address must not be the zero address") {
            assert_not_zero(recipient);
        }

        let (total_supply) = _total_supply.read();
        with_attr error_message("Mint overflow") {
            let (new_total_supply) = SafeUint256.add(total_supply, amount);
        }
        _total_supply.write(new_total_supply);

        let (balance) = _balances.read(recipient);
        let (new_balance) = SafeUint256.add(balance, amount);
        _balances.write(recipient, new_balance);

        Transfer.emit(0, recipient, amount);
        return ();
    }

    func _burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner: felt, amount: Uint256
    ) -> () {
        with_attr error_message("Amount is not a valid Uint256") {
            uint256_check(amount);
        }

        with_attr error_message("Owner address must not be zero") {
            assert_not_zero(owner);
        }

        let (balance) = _balances.read(owner);
        with_attr error_message("Burn amount exceeds balance") {
            let (new_balance: Uint256) = SafeUint256.sub_le(balance, amount);
        }

        _balances.write(owner, new_balance);

        let (total_supply) = _total_supply.read();
        let (new_total_supply) = SafeUint256.sub_le(total_supply, amount);
        _total_supply.write(new_total_supply);
        Transfer.emit(owner, 0, amount);
        return ();
    }

    func _transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        sender: felt, recipient: felt, amount: Uint256
    ) -> () {
        with_attr error_message("Amount is not a valid Uint256") {
            uint256_check(amount);
        }

        with_attr error_message("Sender address must not be zero") {
            assert_not_zero(sender);
        }

        with_attr error_message("Recipient address must not be zero") {
            assert_not_zero(recipient);
        }

        let (sender_balance) = _balances.read(sender);
        with_attr error_message("Transfer amount exceeds sender balance") {
            let (new_sender_balance) = SafeUint256.sub_le(sender_balance, amount);
        }
        _balances.write(sender, new_sender_balance);

        let (recipient_balance) = _balances.read(recipient);
        let (new_recipient_balance) = SafeUint256.add(recipient_balance, amount);
        _balances.write(recipient, new_recipient_balance);
        Transfer.emit(sender, recipient, amount);
        return ();
    }

    func _approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner: felt, spender: felt, amount: Uint256
    ) -> () {
        with_attr error_message("Amount is not a valid Uint256") {
            uint256_check(amount);
        }

        with_attr error_message("Owner address must not be zero") {
            assert_not_zero(owner);
        }

        with_attr error_message("Spender address must not be zero") {
            assert_not_zero(spender);
        }

        _allowances.write(owner, spender, amount);
        Approval.emit(owner, spender, amount);
        return ();
    }

    func _spend_allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner: felt, spender: felt, amount: Uint256
    ) -> () {
        alloc_locals;
        with_attr error_message("Amount is not a valid Uint256") {
            uint256_check(amount);
        }

        let (current_allowance) = _allowances.read(owner, spender);
        let (infinite) = uint256_not(Uint256(0, 0));
        let (is_infinite) = uint256_eq(current_allowance, infinite);

        if (is_infinite == FALSE) {
            with_attr error_message("Insufficient allowance") {
                let (new_allowance) = SafeUint256.sub_le(current_allowance, amount);
            }

            _approve(owner, spender, new_allowance);
            return ();
        }
        return ();
    }
}
