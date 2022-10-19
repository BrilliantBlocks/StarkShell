%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from src.BFR.IBFR import IBFR

const OWNER = 1;

@external
func __setup__() {
    %{
        context.BFR_address = deploy_contract("./src/main/BFR/BFR.cairo", [1]).contract_address
    %}
    return ();
}


@external
func test_registerElement{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local BFR;
    %{
        ids.BFR = context.BFR_address
        stop_prank_callable = start_prank(
            ids.OWNER, target_contract_address=context.BFR_address
        )
    %}
    IBFR.registerElement(BFR, 7);
    %{
        stop_prank_callable()
    %}
    return ();
}
