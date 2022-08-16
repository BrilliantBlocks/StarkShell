%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin


@external
func test_constructor{
        syscall_ptr : felt*,
        range_check_ptr,
        pedersen_ptr : HashBuiltin*
    }():

    %{
        root_address = 231409781234079812347142714327123471437474123978913427
        contract_address = deploy_contract("./src/main.cairo", [root_address]).contract_address
        felt_val = load(contract_address, "root", "felt")
        assert felt_val[0] == root_address
    %}

    return ()
end
