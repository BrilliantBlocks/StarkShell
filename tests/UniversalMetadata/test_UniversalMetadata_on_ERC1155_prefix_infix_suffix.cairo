%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.zkode.diamond.structs import FacetCut, FacetCutAction

from src.zkode.diamond.IDiamond import IDiamond
from src.zkode.facets.upgradability.IDiamondCut import IDiamondCut
from src.zkode.facets.metadata.metadata.IUniversalMetadata import IERC1155Metadata
from src.zkode.interfaces.ITCF import ITCF

from tests.setup import (
    ClassHash,
    getClassHashes,
    computeSelectors,
    declareContracts,
    deployRootDiamondFactory,
    deployRootDiamond,
)

from protostar.asserts import assert_eq

const BrilliantBlocks = 123;
const User = 456;

struct TestData {
    prefix1: felt,
    prefix2: felt,
    suffix1: felt,
    suffix2: felt,
}

func getTestData{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> TestData {
    alloc_locals;

    local prefix1;
    local prefix2;
    local suffix1;
    local suffix2;
    %{
        from tests.util import str_to_felt_array
        array = str_to_felt_array("https://www.brilliantblocks.io/zkode/")
        assert len(array) == 2
        ids.prefix1, ids.prefix2 = array[0], array[1]
        array = str_to_felt_array("/starknet-is-awesome/metadata.json")
        assert len(array) == 2
        ids.suffix1, ids.suffix2 = array[0], array[1]
    %}

    local data: TestData = TestData(prefix1, prefix2, suffix1, suffix2);
    return data;
}

@external
func __setup__{
    syscall_ptr: felt*, bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;

    computeSelectors();
    declareContracts();
    deployRootDiamondFactory();
    deployRootDiamond();

    local rootDiamond;
    %{ ids.rootDiamond = context.rootDiamond %}

    let ch: ClassHash = getClassHashes();

    // User mints a diamond and adds UniversalMetadata and ERC-1155
    let data = getTestData();
    tempvar facetCut: FacetCut* = cast(
        new (FacetCut(ch.metadata, FacetCutAction.Add), FacetCut(ch.erc1155, FacetCutAction.Add)),
        FacetCut*,
    );
    let facetCut_len = 2;
    tempvar calldata: felt* = new (
        11,
        0,
        0,
        0,
        2,
        data.prefix1,
        data.prefix2,
        TRUE,
        2,
        data.suffix1,
        data.suffix2,
        0,
        6,
        User,
        1,
        1,
        0,
        1,
        0,
    );
    let calldata_len = 19;

    %{ stop_prank = start_prank(ids.User, ids.rootDiamond) %}
    let (diamond_address) = ITCF.mintContract(
        rootDiamond, facetCut_len, facetCut, calldata_len, calldata
    );
    %{ stop_prank() %}
    %{ context.diamond_address = ids.diamond_address %}

    return ();
}

@external
func test_uri_returns_prefix_infix_suffix_on_minted_token{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let data = getTestData();
    let (token_uri_len, token_uri) = IERC1155Metadata.uri(diamond_address, Uint256(1, 0));
    assert_eq(token_uri_len, 5);
    local actual_data: TestData = TestData(token_uri[0], token_uri[1], token_uri[3], token_uri[4]);
    let infix1 = token_uri[2];
    let suffix1 = token_uri[3];
    let suffix2 = token_uri[4];
    %{
        from tests.util import felt_array_to_str
        actual_str = felt_array_to_str([ids.token_uri_len, ids.actual_data.prefix1, ids.actual_data.prefix2, ids.infix1, ids.actual_data.suffix1, ids.actual_data.suffix2])
        assert actual_str == "https://www.brilliantblocks.io/zkode/1/starknet-is-awesome/metadata.json"
    %}
    return ();
}

@external
func test_uri_returns_prefix_infix_suffix_on_not_minted_token{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    let data = getTestData();
    let (token_uri_len, token_uri) = IERC1155Metadata.uri(diamond_address, Uint256(2, 1));
    assert_eq(token_uri_len, 6);
    local actual_data: TestData = TestData(token_uri[0], token_uri[1], token_uri[4], token_uri[5]);
    let infix1 = token_uri[2];
    let infix2 = token_uri[3];
    let suffix1 = token_uri[4];
    let suffix2 = token_uri[5];
    %{
        from tests.util import felt_array_to_str
        actual_str = felt_array_to_str([ids.token_uri_len, ids.actual_data.prefix1, ids.actual_data.prefix2, ids.infix1, ids.infix2, ids.suffix1, ids.suffix2])
        assert actual_str == f"https://www.brilliantblocks.io/zkode/{2 + 2**128}/starknet-is-awesome/metadata.json"
    %}
    return ();
}
