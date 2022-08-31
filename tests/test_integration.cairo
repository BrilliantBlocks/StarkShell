%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin

from src.IERC165 import IERC165
from src.constants import IERC165_ID
from src.FacetRegistry.IRegistry import IRegistry
from src.ERC2535.IDiamondCut import IDiamondCut

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


@external
func test_register_facet{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():
    alloc_locals

    local diamond
    local diamondCut_class_hash
    %{
        ids.diamond = context.diamond_address
        ids.diamondCut_class_hash = declare("./src/ERC2535/DiamondCut.cairo").class_hash
    %}

    IRegistry.register(diamond, diamondCut_class_hash)
    let (x_len, x) = IRegistry.resolve(diamond, 1)
    assert_eq(x_len, 1)
    assert_eq(x[0], diamondCut_class_hash)

    let (local dummy: felt*) = alloc()
    # Test that diamondCut is not working
    %{
        expect_revert()
    %}
    IDiamondCut.diamondCut(diamond, 0, 0, 0, 0, dummy)

    return ()
end
