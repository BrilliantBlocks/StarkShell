%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin

from src.constants import IERC165_ID, IERC721_ID
from src.FacetRegistry.IRegistry import IRegistry
from src.IERC165 import IERC165
from src.ERC2535.IDiamondCut import IDiamondCut
from src.ERC2535.IDiamondLoupe import IDiamondLoupe
from src.ERC2535.IDiamond import ICompatibility
from src.constants import FUNCTION_SELECTORS

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
    alloc_locals

    const BrilliantBlocks = 123
    %{
        context.diamondCut_class_hash = declare("./src/ERC2535/DiamondCut.cairo").class_hash
        context.erc721_class_hash = declare("./src/token/ERC721/ERC721.cairo").class_hash
        context.diamond_address = deploy_contract(
                "./src/main.cairo",
                [
                    0,  # _root A root diamond has no parent
                    ids.BrilliantBlocks,  # _owner BrilliantBlocks Account
                    3,  # _facet_key  3 = bin(111)
                    context.erc721_class_hash,
                ],
            ).contract_address
        context.bb = 123
    %}

    return ()
end


# @external
# func test_getImplementation{
#         syscall_ptr : felt*,
#         pedersen_ptr : HashBuiltin*,
#         range_check_ptr,
#     }():
#     alloc_locals
# 
#     local diamond
#     local erc721_class_hash
#     %{
#         ids.diamond = context.diamond_address
#         ids.erc721_class_hash = context.erc721_class_hash
#     %}
# 
#     let (x_len, x) = IDiamondLoupe.facetAddresses(diamond)
#     assert_eq(x_len, 1)
#     assert_eq(x[0], erc721_class_hash)
# 
#     let (new_implementation) = ICompatibility.getImplementation(diamond)
#     assert_eq(new_implementation, erc721_class_hash)
# 
#     return ()
# end
# 
# 
# @external
# func test_diamond_supports_ERC165{
#         syscall_ptr : felt*,
#         pedersen_ptr : HashBuiltin*,
#         range_check_ptr,
#     }():
#     alloc_locals
# 
#     local diamond
#     %{
#         ids.diamond = context.diamond_address
#     %}
# 
#     let (supportsERC165) = IERC165.supportsInterface(diamond, IERC165_ID)
# 
#     assert_eq(supportsERC165, TRUE)
# 
#     let (fff_is_false) = IERC165.supportsInterface(diamond, 0xffffffff)
#     assert_eq(fff_is_false, FALSE)
# 
#     let (supportsERC721) = IERC165.supportsInterface(diamond, IERC721_ID)
# 
#     assert_eq(supportsERC721, TRUE)
# 
#     return ()
# end


@external
func test_register_facet{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():
    alloc_locals

    local diamond
    local diamondCut_class_hash
    local erc721_class_hash
    %{
        ids.diamond = context.diamond_address
        ids.diamondCut_class_hash = context.diamondCut_class_hash
        ids.erc721_class_hash = context.erc721_class_hash
    %}
    let (x_len, x) = IRegistry.resolve(diamond, 3)
    assert_eq(x_len, 1)
    assert_eq(x[0], erc721_class_hash)

    # TODO access rights?
    %{ 
    stop_prank_callable = start_prank(123, target_contract_address=context.diamond_address)
    %}
    IRegistry.register(diamond, diamondCut_class_hash)
    IRegistry.register(diamond, 7)
    %{ stop_prank_callable() %}
    let (x_len, x) = IRegistry.resolve(diamond, 3)
    assert_eq(x_len, 2)
    assert_eq(x[1], diamondCut_class_hash)

    let (facet) = IDiamondLoupe.facetAddress(diamond, 430792745303880346585957116707317276189779144684897836036710359506025130056)
    assert_eq(facet, diamondCut_class_hash)

    let (local dummy: felt*) = alloc()
#     %{
#         expect_revert()
#     %}
    %{ 
    stop_prank_callable = start_prank(123, target_contract_address=context.diamond_address)
    %}
    IDiamondCut.diamondCut(diamond, 7, 0, 0, 0, dummy)
    %{ stop_prank_callable() %}

    # TODO adding more facets than supported becomes tricky
    # TODO what about duplicate facets?

    %{
    stop_prank_callable = start_prank(123, target_contract_address=context.diamond_address)
    %}
    IDiamondCut.diamondCut(diamond, 7, 1, 0, 0, dummy)
    %{ stop_prank_callable() %}
    let (z_len, z) = IDiamondLoupe.facetAddresses(diamond)
    assert_eq(z_len, 2)
    assert_eq(z[0], erc721_class_hash)
    assert_eq(z[1], diamondCut_class_hash)

    return ()
end
