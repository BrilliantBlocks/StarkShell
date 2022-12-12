%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.bootstrap.Bootstrapper import IBootstrapper, ClassHash
from src.starkshell.setShellFun import setShellFun
from src.starkshell.mintContract import mintContract
from src.starkshell.updateMetadata import updateMetadata
from src.zkode.facets.token.erc1155.structs import TokenBatch
from src.zkode.diamond.structs import FacetCut, FacetCutAction
from src.zkode.diamond.IDiamond import IDiamond
from src.zkode.facets.upgradability.IDiamondCut import IDiamondCut
from src.zkode.facets.token.erc1155.IERC1155 import IERC1155
from src.zkode.facets.token.erc721.IERC721 import IERC721
from src.zkode.interfaces.ITCF import ITCF

from protostar.asserts import assert_eq, assert_not_eq

const BrilliantBlocks = 123;
const User = 456;
const Adversary = 789;

struct Selector {
    mintContract: felt,
    setShellFun: felt,
    updateMetadata: felt,
}

func getSelectors() -> Selector {
    alloc_locals;
    local mintContract;
    local setShellFun;
    local updateMetadata;

    %{
        variables = [
            "mintContract",
            "setShellFun",
            "updateMetadata",
            ]
        [setattr(ids, v, getattr(context, v)) if hasattr(context, v) else setattr(ids, v, 0) for v in variables]
    %}

    local selectors: Selector = Selector(
        mintContract,
        setShellFun,
        updateMetadata,
        );

    return selectors;
}

func getClassHashes() -> ClassHash {
    alloc_locals;
    local feltmap;
    local diamond;
    local diamondCut;
    local erc721;
    local erc1155;
    local erc20;
    local erc5114;
    local flobDb;
    local rootDiamondFactory;
    local starkshell;
    local metadata;

    %{
        variables = [
            "feltmap",
            "diamond",
            "diamondCut",
            "erc721",
            "erc1155",
            "erc5114",
            "erc20",
            "flobDb",
            "rootDiamondFactory",
            "starkshell",
            "metadata",
            ]
        [setattr(ids, v, getattr(context, v)) if hasattr(context, v) else setattr(ids, v, 0) for v in variables]
    %}

    local classHashes: ClassHash = ClassHash(
        feltmap,
        diamond,
        diamondCut,
        erc721,
        erc1155,
        erc20,
        erc5114,
        flobDb,
        rootDiamondFactory,
        starkshell,
        metadata,
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
        context.setShellFun = get_selector_from_name("setShellFun")
        context.updateMetadata = get_selector_from_name("updateMetadata")
    %}

    return ();
}

func declareContracts() -> () {
    %{
        context.feltmap = declare("./src/zkode/facets/storage/feltmap/FeltMap.cairo").class_hash
        context.diamond = declare("./src/zkode/diamond/Diamond.cairo").class_hash
        context.diamondCut = declare("./src/zkode/facets/upgradability/DiamondCut.cairo").class_hash
        context.erc721 = declare("./src/zkode/facets/token/erc721/ERC721.cairo").class_hash
        context.erc1155 = declare("./src/zkode/facets/token/erc1155/ERC1155.cairo").class_hash
        context.erc20 = declare("./src/zkode/facets/token/erc20/ERC20.cairo").class_hash
        context.erc5114 = declare("./src/zkode/facets/token/erc5114/ERC5114.cairo").class_hash
        context.flobDb = declare("./src/zkode/facets/storage/flobdb/FlobDB.cairo").class_hash
        context.rootDiamondFactory = declare("./src/bootstrap/Bootstrapper.cairo").class_hash
        context.starkshell = declare("./src/zkode/facets/starkshell/StarkShell.cairo").class_hash
        context.metadata = declare("./src/zkode/facets/metadata/metadata/UniversalMetadata.cairo").class_hash
    %}

    return ();
}

func deployRootDiamondFactory() -> () {
    %{ context.rootFactory = deploy_contract("./src/bootstrap/Bootstrapper.cairo", [0]).contract_address %}

    return ();
}

func deployRootDiamond{
    syscall_ptr: felt*, bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;

    let addr: Address = getAddresses();
    let ch: ClassHash = getClassHashes();
    let sel: Selector = getSelectors();

    let (setShellFun_code_len, setShellFun_code) = setShellFun();
    let (mintContract_code_len, mintContract_code) = mintContract(ch.diamond, ch.erc721);
    let (updateMetadata_code_len, updateMetadata_code) = updateMetadata();

    // TODO prank cheatcode?
    let (rootDiamond) = IBootstrapper.deployRootDiamond(
        addr.rootFactory,
        ch,
        sel.setShellFun,
        setShellFun_code_len,
        setShellFun_code,
        sel.mintContract,
        mintContract_code_len,
        mintContract_code,
        sel.updateMetadata,
        updateMetadata_code_len,
        updateMetadata_code,
    );

    %{ context.rootDiamond = ids.rootDiamond %}

    return ();
}
