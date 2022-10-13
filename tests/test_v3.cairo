%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin


@external
func __setup__() {
    %{
        context.MFP_address = deploy_contract("./src/ERC2535/Diamond.cairo", [0, 0]).contract_address
    %}
    return ();
}


@external
func test_compile() {
    assert 1 = 1;
    return ();
}
