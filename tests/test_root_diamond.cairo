%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin

from src.constants import IERC165_ID, IERC721_ID
from src.FacetRegistry.IRegistry import IRegistry
from src.IERC165 import IERC165
from src.token.ERC721.Imintdeploy import Imintdeploy
from src.ERC2535.IDiamondCut import IDiamondCut
from src.ERC2535.IDiamondLoupe import IDiamondLoupe
from src.ERC2535.IDiamond import ICompatibility
from src.constants import FUNCTION_SELECTORS

from protostar.asserts import assert_eq, assert_not_eq


const BrilliantBlocks = 123;
const User = 456;

namespace FacetConfigKey {
    const OOO = 0;
    const OOI = 1;
    const OIO = 2;
    const OII = 3;
    const IOO = 4;
    const IOI = 5;
    const IIO = 6;
    const III = 7;
}


@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;

    %{
        context.diamond_class_hash = declare("./src/main.cairo").class_hash
        context.diamondCut_class_hash = declare("./src/ERC2535/DiamondCut.cairo").class_hash
        context.erc721_class_hash = declare("./src/token/ERC721/ERC721.cairo").class_hash
        context.mintdeploy_class_hash = declare("./src/token/ERC721/mintdeploy.cairo").class_hash
        context.diamond_address = deploy_contract(
                "./src/main.cairo",
                [
                    0,  # _root A root diamond has no parent
                    ids.BrilliantBlocks,  # _owner BrilliantBlocks Account
                    ids.FacetConfigKey.OII,  # Enable the first two registered facets
                    context.erc721_class_hash,
                ],
            ).contract_address
    %}

    return ();
}


@external
func test_root_diamond_getImplementation{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
    }() {
    alloc_locals;

    local diamond;
    local erc721_class_hash;
    %{
        ids.diamond = context.diamond_address
        ids.erc721_class_hash = context.erc721_class_hash
    %}

    let (facets_len, facets) = IDiamondLoupe.facetAddresses(diamond);
    assert_eq(facets_len, 1);
    assert_eq(facets[0], erc721_class_hash);

    let (new_implementation) = ICompatibility.getImplementation(diamond);
    assert_eq(new_implementation, erc721_class_hash);

    return ();
}


@external
func test_root_diamond_supports_ERC165{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
    }(){
    alloc_locals;

    local diamond;
    %{
        ids.diamond = context.diamond_address
    %}

    let (supportsERC165) = IERC165.supportsInterface(diamond, IERC165_ID);

    assert_eq(supportsERC165, TRUE);

    let (supports_0xffffffff) = IERC165.supportsInterface(diamond, 0xffffffff);
    assert_eq(supports_0xffffffff, FALSE);

    let (supportsERC721) = IERC165.supportsInterface(diamond, IERC721_ID);

    assert_eq(supportsERC721, TRUE);

    return ();
}


@external
func test_root_diamond_is_ERC721{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr,
    }() {
    alloc_locals;

    local diamond;
    local erc721_class_hash;
    %{
        ids.diamond = context.diamond_address
        ids.erc721_class_hash = context.erc721_class_hash
    %}

    // First element in registry is ERC721
    let (resOOI_len, resOOI) = IRegistry.resolve(diamond, FacetConfigKey.OOI);
    assert_eq(resOOI_len, 1);
    assert_eq(resOOI[0], erc721_class_hash);

    // Resolve two facets only returns ERC721
    let (resOII_len, resOII) = IRegistry.resolve(diamond, FacetConfigKey.OII);
    assert_eq(resOII_len, 1);
    assert_eq(resOII[0], erc721_class_hash);

    // Resolving a key not containing ERC721 returns empty array
    let (resOIO_len, resOIO) = IRegistry.resolve(diamond, FacetConfigKey.OIO);
    assert_eq(resOIO_len, 0);

    return ();
}


@external
func test_root_diamond_has_ERC721_ownerOf{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() { 
    alloc_locals;

    local diamond;
    local erc721_class_hash;
    %{
        ids.diamond = context.diamond_address
        ids.erc721_class_hash = context.erc721_class_hash
    %}

    // ownerOf
    let (facet) = IDiamondLoupe.facetAddress(
        diamond, 73122117822990066614852869276021392412342625629800410280609241172256672489
    );
    assert_eq(facet, erc721_class_hash);

    return ();
}


@external
func test_register_facets_in_root_and_diamondCut{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() {
    alloc_locals;

    local diamond;
    local diamond_class_hash;
    local diamondCut_class_hash;
    local erc721_class_hash;
    local mintdeploy_class_hash;
    %{
        ids.diamond = context.diamond_address
        ids.diamond_class_hash = context.diamond_class_hash
        ids.diamondCut_class_hash = context.diamondCut_class_hash
        ids.erc721_class_hash = context.erc721_class_hash
        ids.mintdeploy_class_hash = context.mintdeploy_class_hash
    %}

    // Register diamondCut and mintdeploy facet
    %{
        stop_prank_callable = start_prank(
            ids.BrilliantBlocks, target_contract_address=context.diamond_address
        )
    %}
    IRegistry.register(diamond, diamondCut_class_hash);
    IRegistry.register(diamond, mintdeploy_class_hash);
    %{
        stop_prank_callable()
    %}

    // DiamondCut class is in the second entry
    let (facets_len, facets) = IRegistry.resolve(diamond, 2);
    assert_eq(facets[0], diamondCut_class_hash);

    // Root diamond has diamondCut
    let (facet) = IDiamondLoupe.facetAddress(
        diamond, 430792745303880346585957116707317276189779144684897836036710359506025130056
    );
    assert_eq(facet, diamondCut_class_hash);
    
    // Add some facet to root diamond
    let (local init_params: felt*) = alloc();
    assert init_params[0] = diamond_class_hash;

    %{
        stop_prank_callable = start_prank(
            ids.BrilliantBlocks, target_contract_address=context.diamond_address
        )
    %}
    IDiamondCut.diamondCut(diamond, mintdeploy_class_hash, 0, 1, 1, init_params);
    %{
        stop_prank_callable()
    %}

    // Has a mint function
    let (facet) = IDiamondLoupe.facetAddress(
        diamond, 0x2f0b3c5710379609eb5495f1ecd348cb28167711b73609fe565a72734550354
    );
    assert_eq(facet, mintdeploy_class_hash);

    // A user can mint / deploy new  diamond
    %{
        stop_prank_callable = start_prank(
            ids.User, target_contract_address=context.diamond_address
        )
    %}
    Imintdeploy.mint(diamond, FacetConfigKey.OII);
    %{
        stop_prank_callable()
    %}

    // Remove some mintdeploy_class_hash
    %{
        stop_prank_callable = start_prank(
            ids.BrilliantBlocks, target_contract_address=context.diamond_address
        )
    %}
    IDiamondCut.diamondCut(diamond, mintdeploy_class_hash, 1, 0, 0, init_params);  // ToDo exit params
    %{
        stop_prank_callable()
    %}

    let (z_len, z) = IDiamondLoupe.facetAddresses(diamond);
    assert_eq(z_len, 2);
    assert_eq(z[0], erc721_class_hash);
    assert_eq(z[1], diamondCut_class_hash);

    return ();
}
