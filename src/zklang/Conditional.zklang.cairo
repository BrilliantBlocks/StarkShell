%lang starknet
// SPDX-License: MIT
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.registers import get_label_location

from src.constants import FUNCTION_SELECTORS

// Developing primitive libraries is incentivized by making library a facet.
// Thus, giving access to tokenization and earning interest (of royalties)

// Royalties are merely defined by amount of ERC-1155 tokens
// This should be capped to a reasonable amount (e.g. no library can claim
// more than 0.1%). Thus, burning tokens for reducing the amount of royalties
// is possible.

@external
func __ZKLANG__CONDITIONAL__IF{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _tok1: felt,
    _loc1: felt,
    _fun1: felt,
    _inp1_len: felt,
    _inp1: felt*,
    _tok2: felt,
    _loc2: felt,
    _fun2: felt,
    _inp2_len: felt,
    _inp2: felt*,
    _tok3: felt,
    _loc3: felt, _fun3: felt,
    _inp3_len: felt,
    _inp3: felt*,
    _outp_len: felt,
    _outp: felt*,) -> (res_len: felt, res: felt*) {
    alloc_locals;

    return (res=x+y);
}

// =================
// ZKlang primitives
// =================
@view
@raw_output
func __zklang__() -> (retdata_size: felt, retdata: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (retdata_size=1, retdata=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.ZKLANG.__ZKLANG__CONDITIONAL__IF;
}

// ===================
// Mandatory functions
// ===================

/// @dev Initialize this facet
@external
func __constructor__() -> () {
    return ();
}

/// @dev Remove this facet
@external
func __destructor__() -> () {
    return ();
}

/// @dev Exported view and invokable functions of this facet
@view
@raw_output
func __get_function_selectors__() -> (retdata_size: felt, retdata: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (retdata_size=0, retdata=cast(func_selectors, felt*));

    selectors_start:
}

/// @dev Define all supported interfaces of this facet
@view
func __supports_interface__(_interface_id: felt) -> (res: felt) {
    return (res=FALSE);
}
