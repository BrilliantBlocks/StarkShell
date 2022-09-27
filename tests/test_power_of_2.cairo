%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

from protostar.asserts import assert_eq

from src.power_of_two import power_of_2

@external
func test_power_of_2{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let expected = 1;
    let (actual) = power_of_2(0);
    assert_eq(actual, expected);

    let expected = 1024;
    let (actual) = power_of_2(10);
    assert_eq(actual, expected);

    let expected = 1809251394333065553493296640760748560207343510400633813116524750123642650624;
    let (actual) = power_of_2(250);
    assert_eq(actual, expected);

    return ();
}
