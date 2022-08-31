%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

from protostar.asserts import (
    assert_eq,
)


@external
func __setup__{
#         syscall_ptr : felt*,
#         pedersen_ptr : HashBuiltin*,
#         range_check_ptr,
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
func test_facetAddresses{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():
    assert_eq(1,1)

    return ()
end
