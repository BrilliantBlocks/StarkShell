%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.zkode.diamond.structs import FacetCut, FacetCutAction

from src.zkode.facets.upgradability.IDiamondCut import IDiamondCut
from src.zkode.diamond.IDiamond import IDiamond
from src.zkode.interfaces.ITCF import ITCF
from src.zkode.constants import NULL

from tests.setup import (
    ClassHash,
    get_class_hashes,
    compute_selectors,
    declare_contracts,
    deploy_bootstrapper,
    deploy_root,
)

from protostar.asserts import assert_eq, assert_not_eq

const BrilliantBlocks = 123;
const User = 456;

struct ERC721Calldata {
    receiver: felt,
    tokenId_len: felt,  // 2
    tokenId0: Uint256,
    tokenId1: Uint256,
}

@external
func __setup__{
    syscall_ptr: felt*, bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;

    compute_selectors();
    declare_contracts();
    deploy_bootstrapper();
    deploy_root();

    local root;
    %{ ids.root = context.root %}

    // USER mints a diamond
    let (local FCNULLptr: FacetCut*) = alloc();
    let (local NULLptr: felt*) = alloc();

    %{
        stop_prank_callable = start_prank(
            ids.User, target_contract_address=context.root
        )
    %}
    let (diamond_address) = ITCF.mintContract(root, NULL, FCNULLptr, NULL, NULLptr);
    %{ stop_prank_callable() %}
    %{ context.diamond_address = ids.diamond_address %}

    return ();
}

// / @dev DiamondCut facet has an empty destructor
@external
func test_diamondCut_remove_diamondCut{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = get_class_hashes();

    let (facetCut: FacetCut*) = alloc();
    assert facetCut[0].facetAddress = ch.diamondCut;
    assert facetCut[0].facetCutAction = FacetCutAction.Remove;
    let facetCut_len = 1;
    let (local calldata: felt*) = alloc();
    assert calldata[0] = 0;
    let calldata_len = 1;
    %{
        stop_prank_callable = start_prank(
            ids.User, target_contract_address=context.diamond_address
        )
    %}
    IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank_callable() %}

    // Assert that diamond has no facets
    let (actual_facets_len: felt, actual_facets: felt*) = IDiamond.facetAddresses(diamond_address);
    let expected_facets_len = 0;
    assert_eq(actual_facets_len, expected_facets_len);

    return ();
}

// / @dev ERC721 facet has an empty constructor
@external
func test_diamondCut_add_erc721{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let ch: ClassHash = get_class_hashes();

    let (facetCut: FacetCut*) = alloc();
    assert facetCut[0].facetAddress = ch.erc721;
    assert facetCut[0].facetCutAction = FacetCutAction.Add;
    let facetCut_len = 1;

    let calldata_len = ERC721Calldata.SIZE + 1;
    tempvar calldata = new (
        ERC721Calldata.SIZE,
        ERC721Calldata(
            receiver=User,
            tokenId_len=2,
            tokenId0=Uint256(1, 0),
            tokenId1=Uint256(3, 0),
            ),
        );

    %{
        stop_prank_callable = start_prank(
            ids.User, target_contract_address=context.diamond_address
        )
    %}
    IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank_callable() %}

    // Assert that diamond has exactly diamondCut and ERC721
    let (actual_facets_len: felt, actual_facets: felt*) = IDiamond.facetAddresses(diamond_address);
    let expected_facets_len = 2;
    assert_eq(actual_facets_len, expected_facets_len);
    assert_eq(actual_facets[0], ch.diamondCut);
    assert_eq(actual_facets[1], ch.erc721);

    return ();
}

// TODO test multiple diamondCut
// TODO test reverts
// test with constructor and destructor
// TODO setAlias
// TODO setFunctionFee
