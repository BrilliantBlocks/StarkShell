%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin


@external
func test_init{
        syscall_ptr : felt*,
        range_check_ptr,
        pedersen_ptr : HashBuiltin*
    }():
    alloc_locals
    let root_address = 0x26345BDa8A8Fe248a094a12e517C0c32a2e11b3B3ca2A1be46e9A76DBfD6b65c
    local contract_address: felt

    %{
        ids.contract_address = deploy_contract("./src/main.cairo", [ids.root_address]).contract_address
        felt_val = load(ids.contract_address, "root", "felt")
        assert felt_val[0] == ids.root_address
    %}

    return ()
end
