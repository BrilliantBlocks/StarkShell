%lang starknet
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin

from src.IERC165 import IERC165
from src.constants import IERC165_ID

from protostar.asserts import (
    assert_eq,
    assert_not_eq,
)


@external
func __setup__{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }() -> ():
    %{
        context.diamond_address = deploy_contract(
                "./src/main.cairo",
                [
                    0,  # _root A root diamond has no parent
                    0,  # _facet_key
                ],
            ).contract_address
    %}

    return ()
end


@external
func test_diamond_supports_ERC165{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():
    alloc_locals

    local diamond
    %{
        ids.diamond = context.diamond_address
    %}

    let (supportsERC165) = IERC165.supportsInterface(diamond, IERC165_ID)

    assert_eq(supportsERC165, TRUE)

    let (fff_is_false) = IERC165.supportsInterface(diamond, 0xffffffff)
    assert_eq(fff_is_false, FALSE)

    return ()
end
