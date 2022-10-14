%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.registers import get_label_location

from src.erc20.library import ERC20
from src.constants import FUNCTION_SELECTORS, IERC20_ID



@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    name: felt
) {
    return ERC20.name();
}


@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    symbol: felt
) {
    return ERC20.symbol();
}


@view
func totalSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    total_supply: Uint256
) {
    let (total_supply) = ERC20.total_supply();
    return (total_supply,);
}


@view
func decimals{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    decimals: felt
) {
    return ERC20.decimals();
}


@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) -> (
    balance: Uint256
) {
    return ERC20.balance_of(owner);
}


@view
func allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, spender: felt
) -> (amount: Uint256) {
    let (allowance) = ERC20.allowance(owner, spender);
    return (allowance,);
}


@external
func transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    recipient: felt, amount: Uint256
) -> (success: felt) {
    return ERC20.transfer(recipient, amount);
}


@external
func transferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    sender: felt, recipient: felt, amount: Uint256
) -> (success: felt) {
    return ERC20.transfer_from(sender, recipient, amount);
}


@external
func approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    spender: felt, amount: Uint256
) -> (success: felt) {
    return ERC20.approve(spender, amount);
}


@external
func increaseAllowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    spender: felt, added_amount: Uint256
) -> (success: felt) {
    return ERC20.increase_allowance(spender, added_amount);
}


@external
func decreaseAllowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    spender: felt, subtracted_amount: Uint256
) -> (success: felt) {
    return ERC20.decrease_allowance(spender, subtracted_amount);
}


@external
func __init_facet__{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    name: felt, symbol: felt, decimals: felt, initial_supply: Uint256, recipient: felt
) -> () {

    ERC20.initializer(name, symbol, decimals);
    ERC20._mint(recipient, initial_supply);
    
    return ();
}


@view
func __get_function_selectors__() -> (res_len: felt, res: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (res_len=11, res=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.ERC20.name;
    dw FUNCTION_SELECTORS.ERC20.symbol;
    dw FUNCTION_SELECTORS.ERC20.totalSupply;
    dw FUNCTION_SELECTORS.ERC20.decimals;
    dw FUNCTION_SELECTORS.ERC20.balanceOf;
    dw FUNCTION_SELECTORS.ERC20.allowance;
    dw FUNCTION_SELECTORS.ERC20.transfer;
    dw FUNCTION_SELECTORS.ERC20.transferFrom;
    dw FUNCTION_SELECTORS.ERC20.approve;
    dw FUNCTION_SELECTORS.ERC20.increaseAllowance;
    dw FUNCTION_SELECTORS.ERC20.decreaseAllowance;
}


// @dev Support ERC-165
// @param interface_id
// @return success (0 or 1)
@view
func __supports_interface__(_interface_id: felt) -> (success: felt) {
    if (_interface_id == IERC20_ID) {
        return (TRUE,);
    }

    return (FALSE,);
}
