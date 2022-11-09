%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.ERC1155.IERC1155 import TokenBatch
from src.ERC2535.IDiamond import IDiamond
from src.ERC2535.IDiamondCut import FacetCut, FacetCutAction, IDiamondCut
from src.ERC1155.IERC1155 import IERC1155
from src.main.BFR.IBFR import IBFR
from src.main.TCF.ITCF import ITCF

from protostar.asserts import assert_eq, assert_not_eq

const BrilliantBlocks = 123;
const User = 456;
const Adversary = 789;

struct Setup {
    bfr_classHash: felt,
    diamond_classHash: felt,
    diamondCut_classHash: felt,
    erc721_classHash: felt,
    flobDb_classHash: felt,
    rootAddress: felt,
    self_classHash: felt,
    zklang_classHash: felt,
}

func getSetup() -> Setup {
    alloc_locals;
    local rootAddress;
    local self_classHash;
    local diamond_classHash;
    local diamondCut_classHash;
    local erc721_classHash;
    local bfr_classHash;
    local zklang_classHash;
    local flobDb_classHash;

    %{
        variables = [
            "bfr_classHash",
            "diamond_classHash",
            "diamondCut_classHash",
            "erc721_classHash",
            "flobDb_classHash",
            "rootAddress",
            "self_classHash",
            "zklang_classHash",
            ]
        [setattr(ids, v, getattr(context, v)) if hasattr(context, v) else setattr(ids, v, 0) for v in variables]
    %}

    local setup: Setup = Setup(
        bfr_classHash,
        diamond_classHash,
        diamondCut_classHash,
        erc721_classHash,
        flobDb_classHash,
        rootAddress,
        self_classHash,
        zklang_classHash,
        );

    return setup;
}

func declareContracts() -> () {
    %{
        context.bfr_classHash = declare("./src/BFR/BFR.cairo").class_hash
        context.diamond_classHash = declare("./src/ERC2535/Diamond.cairo").class_hash
        context.diamondCut_classHash = declare("./src/ERC2535/DiamondCut.cairo").class_hash
        context.erc721_classHash = declare("./src/ERC721/ERC721.cairo").class_hash
        context.flobDb_classHash = declare("./src/Storage/FlobDB.cairo").class_hash
        context.self_classHash = declare("./src/ERC2535/Init.cairo").class_hash
        context.zklang_classHash = declare("./src/zklang/ZKlang.cairo").class_hash
    %}

    return ();
}

func deployContracts() -> () {
    %{
        from starkware.starknet.public.abi import get_selector_from_name

        deploy_contract(
                "./src/ERC2535/Init.cairo",
                [
                    context.bfr_classHash,
                    context.diamond_classHash,
                    context.diamondCut_classHash,
                    context.erc721_classHash,
                    context.flobDb_classHash,
                    context.self_classHash,
                    context.zklang_classHash,
                    get_selector_from_name("setZKLfun"),
                    44,  # TODO check
                    43,
                    42,
                    0,
                    1620705241796055304510457292927685118155156568947456526887978951060064028940,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    697690658782096418850967652735536154956637934916358722464095605827630102898,
                    1708453804671938969318547263299793886104586653786513881017476101842785786944,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    519474789671654844181102151028020004295727249970389940992831474254071560581,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                ]
        )
    %}

    return ();
}

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    declareContracts();
    deployContracts();
    let setup = getSetup();

    return ();
}

@external
func test_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let setup = getSetup();

    assert_eq(0, 0);

    return ();
}
