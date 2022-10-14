%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.registers import get_label_location

from src.erc20.library import ERC20
from src.constants import FUNCTION_SELECTORS



@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, amount: Uint256
) {
    ERC20._mint(to, amount);
    return ();
}


@external
func burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, amount: Uint256
) {
    ERC20._burn(from_, amount);
    return ();
}


@external
func __init_facet__{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> () {
    
    return ();
}


@view
func __get_function_selectors__() -> (res_len: felt, res: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (res_len=2, res=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.MINT_BURN_ERC20.mint;
    dw FUNCTION_SELECTORS.MINT_BURN_ERC20.burn;
}


// @dev Support ERC-165
// @param interface_id
// @return success (0 or 1)
@view
func __supports_interface__(_interface_id: felt) -> (success: felt) {
    
    return (FALSE,);
}
