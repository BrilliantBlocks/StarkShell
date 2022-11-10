%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.ERC1155.IERC1155 import TokenBatch
from src.ERC2535.IDiamond import IDiamond
from src.ERC2535.IDiamondCut import FacetCut, FacetCutAction, IDiamondCut
from src.ERC1155.IERC1155 import IERC1155
from src.ERC2535.Init import IRootDiamondFactory, ClassHash
from src.main.BFR.IBFR import IBFR
from src.main.TCF.ITCF import ITCF
from tests.zklang.fun.setZKLangFun import setZKLangFun

from protostar.asserts import assert_eq, assert_not_eq

const BrilliantBlocks = 123;
const User = 456;
const Adversary = 789;

struct Selector {
    setZKLangFun: felt,
}

func getSelectors() -> Selector {
    alloc_locals;
    local setZKLangFun;

    %{
        variables = [
            "setZKLangFun",
            ]
        [setattr(ids, v, getattr(context, v)) if hasattr(context, v) else setattr(ids, v, 0) for v in variables]
    %}

    local selectors: Selector = Selector(
        setZKLangFun,
        );

    return selectors;
}

func getClassHashes() -> ClassHash {
    alloc_locals;
    local bfr;
    local diamond;
    local diamondCut;
    local erc721;
    local flobDb;
    local rootDiamondFactory;
    local zklang;

    %{
        variables = [
            "bfr",
            "diamond",
            "diamondCut",
            "erc721",
            "flobDb",
            "rootDiamondFactory",
            "zklang",
            ]
        [setattr(ids, v, getattr(context, v)) if hasattr(context, v) else setattr(ids, v, 0) for v in variables]
    %}

    local classHashes: ClassHash = ClassHash(
        bfr,
        diamond,
        diamondCut,
        erc721,
        flobDb,
        rootDiamondFactory,
        zklang,
        );

    return classHashes;
}

struct Address {
    rootDiamond: felt,
    rootFactory: felt,
}

func getAddresses() -> Address {
    alloc_locals;
    local rootDiamond;
    local rootFactory;

    %{
        variables = [
            "rootDiamond",
            "rootFactory",
            ]
        [setattr(ids, v, getattr(context, v)) if hasattr(context, v) else setattr(ids, v, 0) for v in variables]
    %}

    local addresses: Address = Address(
        rootDiamond,
        rootFactory,
        );

    return addresses;
}
func computeSelectors() -> () {
    %{
        from starkware.starknet.public.abi import get_selector_from_name
        context.setZKLangFun = get_selector_from_name("setZKLangFun")
    %}

    return ();
}

func declareContracts() -> () {
    %{
        context.bfr = declare("./src/BFR/BFR.cairo").class_hash
        context.diamond = declare("./src/ERC2535/Diamond.cairo").class_hash
        context.diamondCut = declare("./src/ERC2535/DiamondCut.cairo").class_hash
        context.erc721 = declare("./src/ERC721/ERC721.cairo").class_hash
        context.flobDb = declare("./src/Storage/FlobDB.cairo").class_hash
        context.rootDiamondFactory = declare("./src/ERC2535/Init.cairo").class_hash
        context.zklang = declare("./src/zklang/ZKlang.cairo").class_hash
    %}

    return ();
}

func deployRootDiamondFactory() -> () {
    %{ context.rootFactory = deploy_contract("./src/ERC2535/Init.cairo").contract_address %}

    return ();
}

func deployRootDiamond{
    syscall_ptr: felt*, bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;

    let addr: Address = getAddresses();
    let ch: ClassHash = getClassHashes();
    let sel: Selector = getSelectors();

    let (code_len, code) = setZKLangFun();

    let (rootDiamond) = IRootDiamondFactory.deployRootDiamond(
        addr.rootFactory, ch, sel.setZKLangFun, code_len, code
    );

    %{ context.rootDiamond = ids.rootDiamond %}

    return ();
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

    return ();
}

@external
func test_{
    syscall_ptr: felt*, bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    let ch: ClassHash = getClassHashes();
    let addr: Address = getAddresses();

    assert_not_eq(addr.rootDiamond, 0);

    return ();
}
