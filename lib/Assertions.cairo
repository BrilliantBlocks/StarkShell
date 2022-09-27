%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.bool import TRUE
from starkware.starknet.common.syscalls import library_call

from lib.Constants import ASSERT_ONLY_SELF_SELECTOR

@storage_var
func diamond_class_hash() -> (res: felt) {
}

func assert_len_match(selectors_len: felt, facets_len: felt) -> () {
    with_attr error_message("Selector and facet array lengths don't match.") {
        assert selectors_len = facets_len;
    }

    return ();
}

func assert_uint256_is_not_zero{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> () {
    assert_not_zero(token_id.low + token_id.high);
    return ();
}

func felt_is_boolean{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    approved: felt
) -> (res: felt) {
    assert approved * (1 - approved) = 0;
    return (TRUE,);
}

func assert_only_diamond{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    let (diamond_hash) = diamond_class_hash.read();

    // todo replace pedersen_ptr with dummy ptr
    library_call(
        class_hash=diamond_hash,
        function_selector=ASSERT_ONLY_SELF_SELECTOR,
        calldata_size=0,
        calldata=pedersen_ptr,
    );
    return ();
}
