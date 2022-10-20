%lang starknet
from starkware.cairo.common.bool import FALSE, TRUE

from protostar.asserts import assert_eq

from src.ERC2535.library import Library


@external
func test_if_x_eq_true_return_y_else_z_x_is_true() -> () {
    let actual = Library._if_x_eq_true_return_y_else_z(
        x=TRUE,
        y=2,
        z=3,
    );
    let expected = 2;
    assert_eq(actual, expected);
    return ();
}

@external
func test_if_x_eq_true_return_y_else_z_x_is_false() -> () {
    let actual = Library._if_x_eq_true_return_y_else_z(
        x=FALSE,
        y=2,
        z=3,
    );
    let expected = 3;
    assert_eq(actual, expected);
    return ();
}

@external
func test_if_x_eq_true_return_y_else_z_x_is_invalid_reverts() -> () {
    %{
        expect_revert(error_message="BOOL ERROR")
    %}
    let actual = Library._if_x_eq_true_return_y_else_z(
        x=7,
        y=2,
        z=3,
    );
    return ();
}
