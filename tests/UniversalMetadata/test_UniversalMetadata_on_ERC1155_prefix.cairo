%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.ERC2535.IDiamond import IDiamond
from src.ERC2535.IDiamondCut import FacetCut, FacetCutAction, IDiamondCut
from src.UniversalMetadata.IUniversalMetadata import IERC1155Metadata
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

struct TestData {
    prefix1: felt,
    prefix2: felt,
}

func getTestData{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> TestData {
    alloc_locals;

    local prefix1;
    local prefix2;
    %{
        from tests.util import str_to_felt_array
        array = str_to_felt_array("https://www.brilliantblocks.io/zkode/")
        assert len(array) == ids.TestData.SIZE
        ids.prefix1, ids.prefix2 = array[0], array[1]
    %}

    local data: TestData = TestData(
        prefix1,
        prefix2,
    );
    return data;
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

    // User mints a test diamond and adds UniversalMetadata and ERC-1155
    let data = getTestData();
    tempvar facetCut: FacetCut* = cast(new (FacetCut(universalMetadata_class_hash, FacetCutAction.Add),FacetCut(erc1155_class_hash, FacetCutAction.Add),), FacetCut*);
    let facetCut_len = 2;
    tempvar calldata: felt* = new (9, 0, 0, 0, TestData.SIZE, data.prefix1, data.prefix2, FALSE, 0, 0, 6, User, 1, 1, 0, 1, 0);
    let calldata_len = 17;
    %{ stop_prank = start_prank(ids.User, context.TCF_address) %}
    let (diamond_address) = ITCF.mintContract(TCF_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank() %}
    %{ context.diamond_address = ids.diamond_address %}

    return ();
}

@external
func test_uri_returns_prefix_on_minted_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let setup = getSetup();
    let data = getTestData();
    let (token_uri_len, token_uri) = IERC1155Metadata.uri(setup.diamond_address, Uint256(1, 0));
    assert_eq(token_uri_len, TestData.SIZE);
    local actual_data: TestData = TestData(token_uri[0], token_uri[1]);
    %{
        from tests.util import felt_array_to_str
        assert felt_array_to_str([ids.TestData.SIZE, ids.actual_data.prefix1, ids.actual_data.prefix2]) == "https://www.brilliantblocks.io/zkode/"
    %}
    return();
}

@external
func test_uri_returns_prefix_on_not_minted_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let setup = getSetup();
    let data = getTestData();
    let (token_uri_len, token_uri) = IERC1155Metadata.uri(setup.diamond_address, Uint256(2, 1));
    assert_eq(token_uri_len, TestData.SIZE);
    local actual_data: TestData = TestData(token_uri[0], token_uri[1]);
    %{
        from tests.util import felt_array_to_str
        assert felt_array_to_str([ids.TestData.SIZE, ids.actual_data.prefix1, ids.actual_data.prefix2]) == "https://www.brilliantblocks.io/zkode/"
    %}
    return();
}
