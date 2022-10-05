%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_not_zero, split_felt
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.uint256 import Uint256, uint256_check
from starkware.cairo.common.registers import get_label_location

from lib.cairo_math_64x61.contracts.cairo_math_64x61.math64x61 import Math64x61

from src.constants import FUNCTION_SELECTORS, FEE_DENOMINATOR, IERC2981_ID


struct RoyaltyInfo {
    receiver: felt,
    fee: felt,
}


@storage_var
func _royalty_info() -> (res: RoyaltyInfo) {
}


@view
func royaltyInfo{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256, sale_price: Uint256
) -> (receiver: felt, royalty_amount: Uint256) {
    alloc_locals;
    with_attr error_message("ERC2981: token_id is not a valid Uint256") {
        uint256_check(token_id);
    }

    let (royalty) = _royalty_info.read();

    // royalty_amount = sale_price * royalty_fee / 10000
    let fpm_base = Math64x61.fromFelt(FEE_DENOMINATOR);
    let fpm_royalty_fee = Math64x61.fromFelt(royalty.fee);
    let fpm_sale_price = Math64x61.fromUint256(sale_price);

    let royalty_amount_fpm_abs = Math64x61.mul(fpm_royalty_fee, fpm_sale_price);
    let royalty_amount_fpm = Math64x61.div(royalty_amount_fpm_abs, fpm_base);
    let royalty_amount_felt = Math64x61.toFelt(royalty_amount_fpm);
    let (royalty_amount) = convertFeltToUint256(royalty_amount_felt);

    return (royalty.receiver, royalty_amount);
}


func set_royalty{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    receiver: felt, fee: felt
) {

    with_attr error_message("Royalty fee must not exceed the fee denominator (10000)") {
        assert_le(fee, FEE_DENOMINATOR);
    }

    _royalty_info.write(RoyaltyInfo(receiver, fee));
    return ();
}


func convertFeltToUint256{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    input: felt
) -> (output: Uint256) {
    let (output_high, output_low) = split_felt(input);
    let output = Uint256(output_low, output_high);

    return (output,);
}


@external
func __init_facet__{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    receiver: felt, fee: felt
) -> () {
    
    with_attr error_message("Receiver address must not be zero") {
        assert_not_zero(receiver);
    }

    set_royalty(receiver, fee);

    return ();
}


@view
func __get_function_selectors__() -> (res_len: felt, res: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (res_len=1, res=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.ERC2981.royaltyInfo;
}


// @dev Support ERC-165
// @param interface_id
// @return success (0 or 1)
@view
func __supports_interface__(_interface_id: felt) -> (success: felt) {
    if (_interface_id == IERC2981_ID) {
        return (TRUE,);
    }

    return (FALSE,);
}