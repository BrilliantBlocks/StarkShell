%lang starknet
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin

from protostar.asserts import (
        assert_eq,
    )

from src.Diamond import supportsInterface


@external
func test_constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():

    %{
        root_address = 231409781234079812347142714327123471437474123978913427
        contract_address = deploy_contract("./src/Diamond.cairo", [root_address]).contract_address
        felt_val = load(contract_address, "root", "felt")
        assert felt_val[0] == root_address
    %}

    return ()
end


@external
func test_supportsInterface{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():

    let IERC165_ID = 0x01ffc9a7
    let (supports_interface) = supportsInterface(IERC165_ID)
    assert_eq(supports_interface, TRUE)

    return ()
end
