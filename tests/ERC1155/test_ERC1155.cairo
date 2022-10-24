%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.ERC2535.IDiamond import IDiamond
from src.ERC2535.IDiamondCut import FacetCut, FacetCutAction, IDiamondCut
from src.ERC1155.IERC1155 import IERC1155
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
    local erc1155_class_hash;
    %{  
        # Declare diamond and facets
        context.diamond_class_hash = declare("./src/ERC2535/Diamond.cairo").class_hash
        context.diamondCut_class_hash = declare("./src/ERC2535/DiamondCut.cairo").class_hash
        ids.diamondCut_class_hash = context.diamondCut_class_hash
        context.erc1155_class_hash = declare("./src/ERC1155/ERC1155.cairo").class_hash
        ids.erc1155_class_hash = context.erc1155_class_hash
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
    assert elements[1] = erc1155_class_hash;
    let elements_len = 2;
    %{ stop_prank = start_prank(ids.BrilliantBlocks, context.BFR_address) %}
    IBFR.registerElements(TCF_address, elements_len, elements);
    %{ stop_prank() %}

    // User mints a test diamond
    %{ stop_prank = start_prank(ids.User, context.TCF_address) %}
    let (diamond_address) = ITCF.mintContract(TCF_address);
    %{ stop_prank() %}
    %{ context.diamond_address = ids.diamond_address %}

    // Add ERC1155 facet to diamond
    let (local facetCut: FacetCut*) = alloc();
    assert facetCut[0] = FacetCut(erc1155_class_hash, FacetCutAction.Add);
    let facetCut_len = 1;
    let (local calldata: felt*) = alloc();
    assert calldata[0] = 0;
    let calldata_len = 1;
    %{ stop_prank = start_prank(ids.User, context.diamond_address) %}
    IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank() %}
    return ();
}

@external
func test_getImplementation_return_erc1155{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    local erc1155_class_hash;
    %{ ids.erc1155_class_hash = context.erc1155_class_hash %}

    let (token_class_hash) = IDiamond.getImplementation(diamond_address);
    assert_eq(token_class_hash, erc1155_class_hash);
    return ();
}

@external
func test_facet_returns_only_expected_function_selectors{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    
    local erc1155_class_hash;
    %{ ids.erc1155_class_hash = context.erc1155_class_hash %}
    local balanceOf_hash;
    local balanceOfBatch_hash;
    local isApprovedForAll_hash;
    local setApprovalForAll_hash;
    local safeTransferFrom_hash;
    local safeBatchTransferFrom_hash;
    %{
        from starkware.starknet.public.abi import get_selector_from_name
        ids.balanceOf_hash = get_selector_from_name("balanceOf")
        ids.balanceOfBatch_hash = get_selector_from_name("balanceOfBatch")
        ids.isApprovedForAll_hash = get_selector_from_name("isApprovedForAll")
        ids.setApprovalForAll_hash = get_selector_from_name("setApprovalForAll")
        ids.safeTransferFrom_hash = get_selector_from_name("safeTransferFrom")
        ids.safeBatchTransferFrom_hash = get_selector_from_name("safeBatchTransferFrom")
    %}
    // Get all selectors of ERC1155 facet
    let (selectors_len, selectors) = IDiamond.facetFunctionSelectors(diamond_address, erc1155_class_hash);

    // Assert expected number of functions
    assert_eq(selectors_len, 6);

    // Assert that all expected functions are included in ERC-1155
    let (facet) = IDiamond.facetAddress(diamond_address, balanceOf_hash);
    assert_eq(facet, erc1155_class_hash);

    let (facet) = IDiamond.facetAddress(diamond_address, balanceOfBatch_hash);
    assert_eq(facet, erc1155_class_hash);

    let (facet) = IDiamond.facetAddress(diamond_address, isApprovedForAll_hash);
    assert_eq(facet, erc1155_class_hash);

    let (facet) = IDiamond.facetAddress(diamond_address, setApprovalForAll_hash);
    assert_eq(facet, erc1155_class_hash);

    let (facet) = IDiamond.facetAddress(diamond_address, safeTransferFrom_hash);
    assert_eq(facet, erc1155_class_hash);

    let (facet) = IDiamond.facetAddress(diamond_address, safeBatchTransferFrom_hash);
    assert_eq(facet, erc1155_class_hash);

    return ();
}

@external
func test_destructor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() {
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    local erc1155_class_hash;
    %{ ids.erc1155_class_hash = context.erc1155_class_hash %}

    // Remmove ERC1155 facet to diamond
    let (local facetCut: FacetCut*) = alloc();
    assert facetCut[0] = FacetCut(erc1155_class_hash, FacetCutAction.Remove);
    let facetCut_len = 1;
    let (local calldata: felt*) = alloc();
    assert calldata[0] = 0;
    let calldata_len = 1;
    %{ stop_prank = start_prank(ids.User, context.diamond_address) %}
    IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank() %}

    return ();
}
