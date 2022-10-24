%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.ERC2535.IDiamond import IDiamond
from src.ERC2535.IDiamondCut import FacetCut, FacetCutAction, IDiamondCut
from src.main.BFR.IBFR import IBFR
from src.main.TCF.ITCF import ITCF

from protostar.asserts import assert_eq, assert_not_eq

const BrilliantBlocks = 123;
const User = 456;
const Adversary = 789;


@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    local diamondCut_class_hash;
    local universalMetadata_class_hash;
    local erc1155_class_hash;
    local erc20_class_hash;
    local erc5114_class_hash;
    local erc721_class_hash;
    %{  
        # Declare diamond and facets
        context.diamond_class_hash = declare("./src/ERC2535/Diamond.cairo").class_hash
        context.erc1155_class_hash = declare("./src/ERC1155/ERC1155.cairo").class_hash
        ids.erc1155_class_hash = context.erc1155_class_hash;
        context.erc20_class_hash = declare("./src/ERC20/ERC20.cairo").class_hash
        ids.erc20_class_hash =context.erc20_class_hash;
        context.erc5114_class_hash = declare("./src/ERC5114/ERC5114.cairo").class_hash
        ids.erc5114_class_hash = context.erc5114_class_hash;
        context.erc721_class_hash = declare("./src/ERC721/ERC721.cairo").class_hash
        ids.erc721_class_hash = context.erc721_class_hash;
        context.diamondCut_class_hash = declare("./src/ERC2535/DiamondCut.cairo").class_hash
        ids.diamondCut_class_hash = context.diamondCut_class_hash
        context.universalMetadata_class_hash = declare("./src/UniversalMetadata/UniversalMetadata.cairo").class_hash
        ids.universalMetadata_class_hash = context.universalMetadata_class_hash
    %}
    
    local TCF_address;
    %{  
        # Deploy BFR and TCF
        context.BFR_address = deploy_contract(
                "./src/main/BFR/BFR.cairo",
                [
                    ids.BrilliantBlocks, # Owner
                ],
        ).contract_address
        context.TCF_address = deploy_contract(
                "./src/main/TCF/TCF.cairo",
                [
                    context.diamond_class_hash,
                    context.BFR_address,
                    0, # DO_NOT_CARE name
                    0, # DO_NOT_CARE symbol
                    0, # DO_NOT_CARE tokenURI
                ],
        ).contract_address
        ids.TCF_address = context.TCF_address
    %}

    // BrilliantBlocks populates facet registry
    let (local elements: felt*) = alloc();
    assert elements[0] = diamondCut_class_hash;
    assert elements[1] = universalMetadata_class_hash;
    assert elements[2] = erc1155_class_hash;
    assert elements[3] = erc20_class_hash;
    assert elements[4] = erc5114_class_hash;
    assert elements[5] = erc721_class_hash;
    let elements_len = 6;
    %{ stop_prank = start_prank(ids.BrilliantBlocks, context.BFR_address) %}
    IBFR.registerElements(TCF_address, elements_len, elements);
    %{ stop_prank() %}

    // User mints a test diamond
    %{ stop_prank = start_prank(ids.User, context.TCF_address) %}
    let (diamond_address) = ITCF.mintContract(TCF_address);
    %{ stop_prank() %}
    %{ context.diamond_address = ids.diamond_address %}

    let (local facetCut: FacetCut*) = alloc();
    assert facetCut[0] = FacetCut(universalMetadata_class_hash, FacetCutAction.Add);
    let facetCut_len = 1;
    let (local calldata: felt*) = alloc();
    assert calldata[0] = 7;
    assert calldata[1] = 0;
    assert calldata[2] = 0;
    assert calldata[3] = 0;
    assert calldata[4] = 0;
    assert calldata[5] = 0;
    assert calldata[6] = 0;
    assert calldata[7] = 0;
    let calldata_len = 8;

    // User adds UniversalMetadata facet to diamond
    %{ stop_prank = start_prank(ids.User, context.diamond_address) %}
    IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank() %}
    return ();
}

@external
func test_no_returned_function_selectors_without_token_standard {
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() {
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}

    local universalMetadata_class_hash;
    %{ ids.universalMetadata_class_hash = context.universalMetadata_class_hash %}
    let (selectors_len, selectors) = IDiamond.facetFunctionSelectors(diamond_address, universalMetadata_class_hash);
    assert_eq(selectors_len, 0);
    return ();
}

@external
func test_return_only_expected_function_selectors_with_erc1155 {
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() {
    %{ from starkware.starknet.public.abi import get_selector_from_name %}
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    local erc1155_class_hash;
    %{ ids.erc1155_class_hash = context.erc1155_class_hash %}

    let (local facetCut: FacetCut*) = alloc();
    assert facetCut[0] = FacetCut(erc1155_class_hash, FacetCutAction.Add);
    let facetCut_len = 1;
    let (local calldata: felt*) = alloc();
    assert calldata[0] = 6;
    assert calldata[1] = User;
    assert calldata[2] = 1;
    assert calldata[3] = 1;
    assert calldata[4] = 0;
    assert calldata[5] = 1;
    assert calldata[6] = 0;
    let calldata_len = 7;

    // User adds ERC-1155 facet to diamond
    %{ stop_prank = start_prank(ids.User, context.diamond_address) %}
    IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank() %}

    local universalMetadata_class_hash;
    %{ ids.universalMetadata_class_hash = context.universalMetadata_class_hash %}

    let (selectors_len, selectors) = IDiamond.facetFunctionSelectors(diamond_address, universalMetadata_class_hash);
    assert_eq(selectors_len, 1);

    local uri_hash;
    %{ ids.uri_hash = get_selector_from_name("uri") %}
    assert_eq(selectors[0], uri_hash);

    return ();
}

// @external
// func test_return_only_expected_function_selectors_with_erc20 {
//     syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
//     }() {
//     alloc_locals;
//     local diamond_address;
//     %{ ids.diamond_address = context.diamond_address %}
//     local erc721_class_hash;
//     %{ ids.erc721_class_hash = context.erc721_class_hash %}
// 
//     let (local facetCut: FacetCut*) = alloc();
//     assert facetCut[0] = FacetCut(erc721_class_hash, FacetCutAction.Add);
//     let facetCut_len = 1;
//     // TODO init
//     let (local calldata: felt*) = alloc();
//     assert calldata[0] = 7;
//     assert calldata[1] = 0;
//     assert calldata[2] = 0;
//     assert calldata[3] = 0;
//     assert calldata[4] = 0;
//     assert calldata[5] = 0;
//     assert calldata[6] = 0;
//     assert calldata[7] = 0;
//     let calldata_len = 8;
// 
//     // User adds ERC-721 facet to diamond
//     %{ stop_prank = start_prank(ids.User, context.diamond_address) %}
//     IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
//     %{ stop_prank() %}
// 
//     local universalMetadata_class_hash;
//     %{ ids.universalMetadata_class_hash = context.universalMetadata_class_hash %}
// 
//     let (selectors_len, selectors) = IDiamond.facetFunctionSelectors(diamond_address, universalMetadata_class_hash);
//     // TODO how many and which functions
//     assert_eq(selectors_len, 0);
// 
//     return ();
// }
// 
// @external
// func test_return_only_expected_function_selectors_with_erc5114 {
//     syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
//     }() {
//     alloc_locals;
//     local diamond_address;
//     %{ ids.diamond_address = context.diamond_address %}
//     local erc721_class_hash;
//     %{ ids.erc721_class_hash = context.erc721_class_hash %}
// 
//     let (local facetCut: FacetCut*) = alloc();
//     assert facetCut[0] = FacetCut(erc721_class_hash, FacetCutAction.Add);
//     let facetCut_len = 1;
//     // TODO init
//     let (local calldata: felt*) = alloc();
//     assert calldata[0] = 7;
//     assert calldata[1] = 0;
//     assert calldata[2] = 0;
//     assert calldata[3] = 0;
//     assert calldata[4] = 0;
//     assert calldata[5] = 0;
//     assert calldata[6] = 0;
//     assert calldata[7] = 0;
//     let calldata_len = 8;
// 
//     // User adds ERC-721 facet to diamond
//     %{ stop_prank = start_prank(ids.User, context.diamond_address) %}
//     IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
//     %{ stop_prank() %}
// 
//     local universalMetadata_class_hash;
//     %{ ids.universalMetadata_class_hash = context.universalMetadata_class_hash %}
// 
//     let (selectors_len, selectors) = IDiamond.facetFunctionSelectors(diamond_address, universalMetadata_class_hash);
//     // TODO how many and which functions
//     assert_eq(selectors_len, 0);
// 
//     return ();
// }
// 
// @external
// func test_return_only_expected_function_selectors_with_erc721 {
//     syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
//     }() {
//     alloc_locals;
//     local diamond_address;
//     %{ ids.diamond_address = context.diamond_address %}
//     local erc721_class_hash;
//     %{ ids.erc721_class_hash = context.erc721_class_hash %}
// 
//     let (local facetCut: FacetCut*) = alloc();
//     assert facetCut[0] = FacetCut(erc721_class_hash, FacetCutAction.Add);
//     let facetCut_len = 1;
//     // TODO init
//     let (local calldata: felt*) = alloc();
//     assert calldata[0] = 7;
//     assert calldata[1] = 0;
//     assert calldata[2] = 0;
//     assert calldata[3] = 0;
//     assert calldata[4] = 0;
//     assert calldata[5] = 0;
//     assert calldata[6] = 0;
//     assert calldata[7] = 0;
//     let calldata_len = 8;
// 
//     // User adds ERC-721 facet to diamond
//     %{ stop_prank = start_prank(ids.User, context.diamond_address) %}
//     IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
//     %{ stop_prank() %}
// 
//     local universalMetadata_class_hash;
//     %{ ids.universalMetadata_class_hash = context.universalMetadata_class_hash %}
// 
//     let (selectors_len, selectors) = IDiamond.facetFunctionSelectors(diamond_address, universalMetadata_class_hash);
//     // TODO how many and which functions
//     assert_eq(selectors_len, 0);
// 
//     return ();
// }
