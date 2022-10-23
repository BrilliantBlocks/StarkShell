%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.ERC2535.IDiamondCut import FacetCut, FacetCutAction, IDiamondCut
from src.ERC20.IERC20 import IERC20
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
    local erc20_class_hash;
    %{  
        # Declare diamond and facets
        context.diamond_class_hash = declare("./src/ERC2535/Diamond.cairo").class_hash
        context.diamondCut_class_hash = declare("./src/ERC2535/DiamondCut.cairo").class_hash
        ids.diamondCut_class_hash = context.diamondCut_class_hash
        context.erc20_class_hash = declare("./src/ERC20/ERC20.cairo").class_hash
        ids.erc20_class_hash = context.erc20_class_hash
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
    assert elements[1] = erc20_class_hash;
    let elements_len = 2;
    %{ stop_prank = start_prank(ids.BrilliantBlocks, context.BFR_address) %}
    IBFR.registerElements(TCF_address, elements_len, elements);
    %{ stop_prank() %}

    // User mints a test diamond
    %{ stop_prank = start_prank(ids.User, context.TCF_address) %}
    let (diamond_address) = ITCF.mintContract(TCF_address);
    %{ stop_prank() %}
    %{ context.diamond_address = ids.diamond_address %}

    return ();
}

@external
func test_constructor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() {
    alloc_locals;
    local diamond_address;
    %{ ids.diamond_address = context.diamond_address %}
    local erc20_class_hash;
    %{ ids.erc20_class_hash = context.erc20_class_hash %}

    let (local facetCut: FacetCut*) = alloc();
    assert facetCut[0] = FacetCut(erc20_class_hash, FacetCutAction.Add);
    let facetCut_len = 1;
    let (local calldata: felt*) = alloc();
    assert calldata[0] = 3;  // calldata_len for ERC-20 facet
    assert calldata[1] = User;
    assert calldata[2] = 1000000;
    assert calldata[3] = 0;
    let calldata_len = 4;

    // User adds ERC20 facet to diamond
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