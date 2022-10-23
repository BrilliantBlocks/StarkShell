%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin

from src.constants import NULL
from src.ERC2535.IDiamondCut import FacetCut, FacetCutAction, IDiamondCut
from src.ERC2535.IDiamond import IDiamond
from src.main.BFR.IBFR import IBFR
from src.main.TCF.ITCF import ITCF

from protostar.asserts import assert_eq, assert_not_eq


const BrilliantBlocks = 123;
const User = 456;


@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    local BFR_address;
    local TCF_address;
    local diamondCut_class_hash;
    local erc721_class_hash;
    // Deploy BFR and TCF
    %{
        ids.BFR_address = deploy_contract("./src/main/BFR/BFR.cairo", [ids.BrilliantBlocks]).contract_address
        context.diamond_class_hash = declare("./src/ERC2535/Diamond.cairo").class_hash
        context.diamondCut_class_hash = declare("./src/ERC2535/DiamondCut.cairo").class_hash
        ids.diamondCut_class_hash = context.diamondCut_class_hash
        context.erc721_class_hash = declare("./src/ERC721/ERC721.cairo").class_hash
        ids.erc721_class_hash = context.erc721_class_hash;
        context.TCF_address = deploy_contract(
                "./src/main/TCF/TCF.cairo",
                [
                    context.diamond_class_hash,
                    ids.BFR_address,
                    0, # name
                    0, # symbol
                    0, # uri
                ],
            ).contract_address
        ids.TCF_address = context.TCF_address

        stop_prank_callable = start_prank(
            ids.BrilliantBlocks, target_contract_address=ids.BFR_address
        )
    %}

    // BrilliantBlocks add DiamondCut and ERC721 to BFR
    let (local elements: felt*) = alloc();
    assert elements[0] = diamondCut_class_hash;
    assert elements[1] = erc721_class_hash;
    IBFR.registerElements(BFR_address, 2, elements);
    %{ stop_prank_callable() %}

    // USER mints a diamond
    %{
        stop_prank_callable = start_prank(
            ids.User, target_contract_address=context.TCF_address
        )
    %}
    let (diamond_address) = ITCF.mintContract(TCF_address);
    %{ stop_prank_callable() %}
    %{ context.diamond_address = ids.diamond_address %}
    return ();
}

/// @dev DiamondCut facet has an empty destructor
@external
func test_diamondCut_remove_diamondCut{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() {
    alloc_locals;
    local TCF_address;
    local erc721_class_hash;
    local diamondCut_class_hash;
    local diamond_address;
    %{
        ids.TCF_address = context.TCF_address;
        ids.erc721_class_hash = context.erc721_class_hash;
        ids.diamondCut_class_hash = context.diamondCut_class_hash
        ids.diamond_address = context.diamond_address;

        stop_prank_callable = start_prank(
            ids.User, target_contract_address=ids.diamond_address
        )
    %}

    let (facetCut: FacetCut*) = alloc();
    assert facetCut[0].facetAddress = diamondCut_class_hash;
    assert facetCut[0].facetCutAction = FacetCutAction.Remove;
    let facetCut_len = 1;
    let (local calldata: felt*) = alloc();
    assert calldata[0] = 0;
    let calldata_len = 1;
    IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank_callable() %}

    // Assert that diamond has no facets
    let (actual_facets_len: felt, actual_facets: felt*) = IDiamond.facetAddresses(diamond_address);
    let expected_facets_len = 0;
    assert_eq(actual_facets_len, expected_facets_len);

    return ();
}

/// @dev ERC721 facet has an empty constructor
@external
func test_diamondCut_add_erc721{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() {
    alloc_locals;
    local erc721_class_hash;
    local diamondCut_class_hash;
    local diamond_address;
    %{
        ids.erc721_class_hash = context.erc721_class_hash;
        ids.diamondCut_class_hash = context.diamondCut_class_hash
        ids.diamond_address = context.diamond_address;

        stop_prank_callable = start_prank(
            ids.User, target_contract_address=ids.diamond_address
        )
    %}

    let (facetCut: FacetCut*) = alloc();
    assert facetCut[0].facetAddress = erc721_class_hash;
    assert facetCut[0].facetCutAction = FacetCutAction.Add;
    let facetCut_len = 1;
    let (local calldata: felt*) = alloc();
    assert calldata[0] = 0;
    let calldata_len = 1;
    IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank_callable() %}

    // Assert that diamond has exactly diamondCut and ERC721
    let (actual_facets_len: felt, actual_facets: felt*) = IDiamond.facetAddresses(diamond_address);
    let expected_facets_len = 2;
    assert_eq(actual_facets_len, expected_facets_len);
    assert_eq(actual_facets[0], diamondCut_class_hash);
    assert_eq(actual_facets[1], erc721_class_hash);

    return ();
}

// TODO test multiple diamondCut
// TODO test reverts
// test with constructor and destructor
// TODO setAlias
// TODO setFunctionFee
