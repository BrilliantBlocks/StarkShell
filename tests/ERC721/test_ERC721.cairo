%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.ERC2535.IDiamond import IDiamond
from src.ERC2535.IDiamondCut import FacetCut, FacetCutAction, IDiamondCut
from src.ERC721.IERC721 import IERC721
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
    local erc721_class_hash;
    %{  
        # Declare diamond and facets
        context.diamond_class_hash = declare("./src/ERC2535/Diamond.cairo").class_hash
        context.diamondCut_class_hash = declare("./src/ERC2535/DiamondCut.cairo").class_hash
        ids.diamondCut_class_hash = context.diamondCut_class_hash
        context.erc721_class_hash = declare("./src/ERC721/ERC721.cairo").class_hash
        ids.erc721_class_hash = context.erc721_class_hash
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
    assert elements[1] = erc721_class_hash;
    let elements_len = 2;
    %{ stop_prank = start_prank(ids.BrilliantBlocks, context.BFR_address) %}
    IBFR.registerElements(TCF_address, elements_len, elements);
    %{ stop_prank() %}

    // User mints a test diamond
    %{ stop_prank = start_prank(ids.User, context.TCF_address) %}
    let (diamond_address) = ITCF.mintContract(TCF_address);
    %{ stop_prank() %}
    %{ context.diamond_address = ids.diamond_address %}

    // Add ERC721 facet to diamond
    let (local facetCut: FacetCut*) = alloc();
    assert facetCut[0] = FacetCut(erc721_class_hash, FacetCutAction.Add);
    let facetCut_len = 1;
    let (local calldata: felt*) = alloc();
    let calldata_len = 0;
    %{ stop_prank = start_prank(ids.User, context.diamond_address) %}
    IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank() %}
    return ();
}

@external
func test_getImplementation_return_erc721{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    local erc721_class_hash;
    %{ ids.erc721_class_hash = context.erc721_class_hash %}

    let (token_class_hash) = IDiamond.getImplementation(diamond_address);
    assert_eq(token_class_hash, erc721_class_hash);
    return ();
}

@external
func test_facet_returns_only_expected_function_selectors{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    local erc721_class_hash;
    %{ ids.erc721_class_hash = context.erc721_class_hash %}
    local balanceOf_hash;
    local ownerOf_hash;
    local getApproved_hash;
    local isApprovedForAll_hash;
    local approve_hash;
    local setApprovalForAll_hash;
    local transferFrom_hash;
    local safeTransferFrom_hash;
    %{
        from starkware.starknet.public.abi import get_selector_from_name
        ids.balanceOf_hash = get_selector_from_name("balanceOf")
        ids.ownerOf_hash = get_selector_from_name("ownerOf")
        ids.getApproved_hash = get_selector_from_name("getApproved")
        ids.isApprovedForAll_hash = get_selector_from_name("isApprovedForAll")
        ids.approve_hash = get_selector_from_name("approve")
        ids.setApprovalForAll_hash = get_selector_from_name("setApprovalForAll")
        ids.transferFrom_hash = get_selector_from_name("transferFrom")
        ids.safeTransferFrom_hash = get_selector_from_name("safeTransferFrom")
    %}

    let (selectors_len, selectors) = IDiamond.facetFunctionSelectors(diamond_address, erc721_class_hash);
    assert_eq(selectors_len, 8);

    let (facet) = IDiamond.facetAddress(diamond_address, balanceOf_hash);
    assert_eq(facet, erc721_class_hash);

    let (facet) = IDiamond.facetAddress(diamond_address, ownerOf_hash);
    assert_eq(facet, erc721_class_hash);

    let (facet) = IDiamond.facetAddress(diamond_address, getApproved_hash);
    assert_eq(facet, erc721_class_hash);

    let (facet) = IDiamond.facetAddress(diamond_address, isApprovedForAll_hash);
    assert_eq(facet, erc721_class_hash);

    let (facet) = IDiamond.facetAddress(diamond_address, approve_hash);
    assert_eq(facet, erc721_class_hash);

    let (facet) = IDiamond.facetAddress(diamond_address, setApprovalForAll_hash);
    assert_eq(facet, erc721_class_hash);

    let (facet) = IDiamond.facetAddress(diamond_address, transferFrom_hash);
    assert_eq(facet, erc721_class_hash);

    let (facet) = IDiamond.facetAddress(diamond_address, safeTransferFrom_hash);
    assert_eq(facet, erc721_class_hash);

    return ();
}

@external
func test_destructor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() {
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    local erc721_class_hash;
    %{ ids.erc721_class_hash = context.erc721_class_hash %}

    // Remmove ERC721 facet to diamond
    let (local facetCut: FacetCut*) = alloc();
    assert facetCut[0] = FacetCut(erc721_class_hash, FacetCutAction.Remove);
    let facetCut_len = 1;
    let (local calldata: felt*) = alloc();
    let calldata_len = 0;
    %{ stop_prank = start_prank(ids.User, context.diamond_address) %}
    IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank() %}

    local owner;
    local balance;
    local token_approval;
    local operator_approval;
    %{
        ids.owner = load(context.diamond_address, "owners_", "felt", key=[1, 0])[0]
        balance = load(context.diamond_address, "balances_", "Uint256", key=[ids.User])
        ids.balance = balance[0] + 2**128 * balance[1]
        ids.token_approval = load(context.diamond_address, "token_approvals_", "felt",key=[1, 0])[0]
        ids.operator_approval = load(context.diamond_address, "operator_approvals_", "felt", key=[ids.User, ids.Adversary])[0]
    %}

    // Assert that storage variables are not initialized
    assert_eq(owner, 0);
    assert_eq(balance, 0);
    assert_eq(token_approval, 0);
    assert_eq(operator_approval, 0);

    return ();
}
