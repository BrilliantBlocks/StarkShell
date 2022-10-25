%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.constants import NULL
from src.ERC1155.IERC1155 import IERC1155
from src.ERC2535.IDiamondCut import FacetCut, FacetCutAction, IDiamondCut, ILanguage
from src.ERC2535.IDiamond import IDiamond
from src.main.BFR.IBFR import IBFR
from src.main.TCF.ITCF import ITCF

from protostar.asserts import assert_eq, assert_not_eq


const BrilliantBlocks = 123;
const User = 456;

struct Setup {
    diamond_address: felt,
    diamondCut_class_hash: felt,
}

func getSetup{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> Setup {
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    local diamondCut_class_hash;
    %{ ids.diamondCut_class_hash = context.diamondCut_class_hash %}
    
    let setup = Setup(diamond_address, diamondCut_class_hash);
    return setup;
}

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    local BFR_address;
    local TCF_address;
    local diamondCut_class_hash;
    local erc1155_class_hash;
    // Deploy BFR and TCF
    %{
        ids.BFR_address = deploy_contract("./src/main/BFR/BFR.cairo", [ids.BrilliantBlocks]).contract_address
        context.diamond_class_hash = declare("./src/ERC2535/Diamond.cairo").class_hash
        context.diamondCut_class_hash = declare("./src/ERC2535/DiamondCut.cairo").class_hash
        context.erc1155_class_hash = declare("./src/ERC1155/ERC1155.cairo").class_hash
        ids.erc1155_class_hash = context.erc1155_class_hash
        ids.diamondCut_class_hash = context.diamondCut_class_hash
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

    // BrilliantBlocks add DiamondCut BFR
    let (local elements: felt*) = alloc();
    assert elements[0] = diamondCut_class_hash;
    assert elements[1] = erc1155_class_hash;
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

    // Add ERC1155 facet to diamond
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
    %{ stop_prank = start_prank(ids.User, context.diamond_address) %}
    IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
    %{ stop_prank() %}
    return ();
}

@contract_interface
namespace AliasFunctions {
    func foo(owner: felt, token_id: Uint256) -> (res: Uint256) {
    }
}

@external
func test_setAlias{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let setup = getSetup();
    local foo;
    local foo_selector;
    local balanceOf_selector;
    local setAlias_selector;
    %{
        from starkware.starknet.public.abi import get_selector_from_name
        from tests.util import str_to_felt
        ids.foo = str_to_felt("foo")
        ids.foo_selector = get_selector_from_name("foo")
        ids.balanceOf_selector = get_selector_from_name("balanceOf")
        ids.setAlias_selector = get_selector_from_name("setAlias")
    %}
    let (user_balance_origin) = IERC1155.balanceOf(setup.diamond_address, User, Uint256(1, 0));
    assert_eq(user_balance_origin.low, 1);
    assert_eq(user_balance_origin.high, 0);

    %{ stop_prank = start_prank(ids.User, context.diamond_address) %}
    ILanguage.setAlias(setup.diamond_address, foo, foo_selector, balanceOf_selector);
    %{ stop_prank() %}

    let (user_balance_alias) = AliasFunctions.foo(setup.diamond_address, User, Uint256(1, 0));
    assert_eq(user_balance_alias.low, 1);
    assert_eq(user_balance_alias.high, 0);
    
    return ();
}
