%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.ERC1155.IERC1155 import TokenBatch
from src.ERC2535.IDiamond import IDiamond
from src.ERC2535.IDiamondCut import FacetCut, FacetCutAction, IDiamondCut
from src.ERC1155.IERC1155 import IERC1155
from bootstrap.Bootstrapper import IBootstrapper, ClassHash
from src.ERC721.IERC721 import IERC721
from src.interfaces.IBFR import IBFR
from src.interfaces.ITCF import ITCF
from src.zklang.IZKlang import IZKlang
from tests.zklang.fun.setZKLangFun import setZKLangFun
from tests.zklang.fun.mintContract import mintContract

from protostar.asserts import assert_eq, assert_not_eq

const BrilliantBlocks = 123;
const User = 456;
const Adversary = 789;

struct Selector {
    mintContract: felt,
    setZKLangFun: felt,
}

func getSelectors() -> Selector {
    alloc_locals;
    local mintContract;
    local setZKLangFun;

    %{
        variables = [
            "mintContract",
            "setZKLangFun",
            ]
        [setattr(ids, v, getattr(context, v)) if hasattr(context, v) else setattr(ids, v, 0) for v in variables]
    %}

    local selectors: Selector = Selector(
        mintContract,
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
    local erc1155;
    local erc20;
    local flobDb;
    local rootDiamondFactory;
    local zklang;

    %{
        variables = [
            "bfr",
            "diamond",
            "diamondCut",
            "erc721",
            "erc1155",
            "erc20",
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
        erc1155,
        erc20,
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
        context.mintContract = get_selector_from_name("mintContract")
        context.setZKLangFun = get_selector_from_name("setZKLangFun")
    %}

    return ();
}

func declareContracts() -> () {
    %{
        context.bfr = declare("./src/Storage/BFR/BFR.cairo").class_hash
        context.diamond = declare("./src/ERC2535/Diamond.cairo").class_hash
        context.diamondCut = declare("./src/ERC2535/DiamondCut.cairo").class_hash
        context.erc721 = declare("./src/ERC721/ERC721.cairo").class_hash
        context.erc1155 = declare("./src/ERC1155/ERC1155.cairo").class_hash
        context.erc20 = declare("./src/ERC20/ERC20.cairo").class_hash
        context.flobDb = declare("./src/Storage/FlobDB.cairo").class_hash
        context.rootDiamondFactory = declare("./bootstrap/Bootstrapper.cairo").class_hash
        context.zklang = declare("./src/zklang/ZKlang.cairo").class_hash
        print(context.diamond)
        print(context.erc721)
    %}

    return ();
}

func deployRootDiamondFactory() -> () {
    %{ context.rootFactory = deploy_contract("./bootstrap/Bootstrapper.cairo", [0]).contract_address %}

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
    let (mintContract_code_len, mintContract_code) = mintContract(ch.diamond, ch.erc721);

    // TODO prank cheatcode?
    let (rootDiamond) = IBootstrapper.deployRootDiamond(
        addr.rootFactory,
        ch,
        sel.setZKLangFun,
        code_len,
        code,
        sel.mintContract,
        mintContract_code_len,
        mintContract_code,
    );

    %{ context.rootDiamond = ids.rootDiamond %}

    return ();
}
