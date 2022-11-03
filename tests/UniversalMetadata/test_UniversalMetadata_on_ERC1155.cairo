%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.ERC2535.IDiamond import IDiamond
from src.ERC2535.IDiamondCut import FacetCut, FacetCutAction, IDiamondCut
from src.main.BFR.IBFR import IBFR
from src.main.TCF.ITCF import ITCF

from protostar.asserts import assert_eq

const BrilliantBlocks = 123;
const User = 456;


struct Setup {
    diamond_address: felt,
    universalMetadata_class_hash: felt,
    erc1155_class_hash: felt,
}

func getSetup{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> Setup {
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    local universalMetadata_class_hash;
    %{ ids.universalMetadata_class_hash = context.universalMetadata_class_hash %}
    local erc1155_class_hash;
    %{ ids.erc1155_class_hash = context.erc1155_class_hash %}

    local setup: Setup = Setup(
        diamond_address,
        universalMetadata_class_hash,
        erc1155_class_hash,
    );
    return setup;
}

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    local diamondCut_class_hash;
    local universalMetadata_class_hash;
    local erc1155_class_hash;
    %{  
        # Declare diamond and facets
        context.diamond_class_hash = declare("./src/ERC2535/Diamond.cairo").class_hash
        context.erc1155_class_hash = declare("./src/ERC1155/ERC1155.cairo").class_hash
        ids.erc1155_class_hash = context.erc1155_class_hash;
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
    tempvar elements: felt* = new (diamondCut_class_hash, universalMetadata_class_hash, erc1155_class_hash,);
    let elements_len = 3;
    %{ stop_prank = start_prank(ids.BrilliantBlocks, context.BFR_address) %}
    IBFR.registerElements(TCF_address, elements_len, elements);
    %{ stop_prank() %}

    // User mints a diamond with UniversalMetadata and ERC-1155
    tempvar facetCut: FacetCut* = cast(new (FacetCut(universalMetadata_class_hash, FacetCutAction.Add),FacetCut(erc1155_class_hash, FacetCutAction.Add),), FacetCut*);
    let facetCut_len = 2;
    tempvar calldata: felt* = new (7, 0, 0, 0, 0, 0, 0, 0, 6, User, 1, 1, 0, 1, 0,);
    let calldata_len = 15;

    %{ stop_prank = start_prank(ids.User, context.TCF_address) %}
    let (diamond_address) = ITCF.mintContract(TCF_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank() %}
    %{ context.diamond_address = ids.diamond_address %}

    return ();
}

@external
func test_facetFunctionSelectors_returns_one_selector {
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() {
    let setup = getSetup();
    let (selectors_len, selectors) = IDiamond.facetFunctionSelectors(setup.diamond_address, setup.universalMetadata_class_hash);
    assert_eq(selectors_len, 1);
    return ();
}

@external
func test_facetAddress_of_uri_returns_universal_metadata_class_hash {
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() {
    %{ from starkware.starknet.public.abi import get_selector_from_name %}
    alloc_locals;
    let setup = getSetup();
    local uri;
    %{ ids.uri = get_selector_from_name("uri") %}
    let (actual_facet) = IDiamond.facetAddress(setup.diamond_address, uri);
    assert_eq(actual_facet, setup.universalMetadata_class_hash);
    return ();
}

@external
func test_supportsInterface_returns_true_on_erc1155_without_token_facet{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let setup = getSetup();
    const IERC1155_METADATA_ID = 0x0e89341c;
    let (supportsIERC1155) = IDiamond.supportsInterface(setup.diamond_address, IERC1155_METADATA_ID);
    assert_eq(supportsIERC1155, TRUE);
    return ();
}

@external
func test_supportsInterface_returns_false_on_erc20_without_token_facet{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let setup = getSetup();
    const IERC20_METADATA_ID = 0x942e8b22;
    let (supportsIERC20) = IDiamond.supportsInterface(setup.diamond_address, IERC20_METADATA_ID);
    assert_eq(supportsIERC20, FALSE);
    return ();
}

@external
func test_supportsInterface_returns_false_on_erc721_without_token_facet{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let setup = getSetup();
    const IERC721_METADATA_ID = 0x5b5e139f;
    let (supportsIERC721) = IDiamond.supportsInterface(setup.diamond_address, IERC721_METADATA_ID);
    assert_eq(supportsIERC721, FALSE);
    return ();
}

@external
func test_supportsInterface_returns_false_on_erc5114_without_token_facet{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let setup = getSetup();
    const IERC5114_METADATA_ID = 0x6cea869c;
    let (supportsIERC5114) = IDiamond.supportsInterface(setup.diamond_address, IERC5114_METADATA_ID);
    assert_eq(supportsIERC5114, FALSE);
    return ();
}
