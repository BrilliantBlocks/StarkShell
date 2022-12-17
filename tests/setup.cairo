%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.bootstrap.Bootstrapper import IBootstrapper
from src.bootstrap.config.calldata import get_calldata
from src.bootstrap.structs import ClassHash

from protostar.asserts import assert_eq, assert_not_eq

const BrilliantBlocks = 123;
const User = 456;
const Adversary = 789;

struct Selector {
    mintContract: felt,
    setShellFun: felt,
    updateMetadata: felt,
}

func get_selectors() -> Selector {
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

func get_class_hashes() -> ClassHash {
    alloc_locals;
    local diamondCut;
    local erc721;
    local feltmap;
    local flobDb;
    local metadata;
    local starkshell;

    %{
        variables = [
            "diamondCut",
            "erc721",
            "feltmap",
            "flobDb",
            "metadata",
            "starkshell",
            ]
        [setattr(ids, v, getattr(context, v)) if hasattr(context, v) else setattr(ids, v, 0) for v in variables]
    %}

    local classHashes: ClassHash = ClassHash(
        diamondCut=diamondCut,
        erc721=erc721,
        feltmap=feltmap,
        flobDb=flobDb,
        metadata=metadata,
        starkshell=starkshell,
        );

    return classHashes;
}

func compute_selectors() -> () {
    %{
        from starkware.starknet.public.abi import get_selector_from_name
        context.mintContract = get_selector_from_name("mintContract")
        context.setShellFun = get_selector_from_name("setShellFun")
        context.updateMetadata = get_selector_from_name("updateMetadata")
    %}

    return ();
}

func declare_contracts() -> () {
    %{
        context.feltmap = declare("./src/zkode/facets/storage/feltmap/FeltMap.cairo").class_hash
        context.declared_diamond = declare("./src/zkode/diamond/Diamond.cairo")
        context.diamond =  context.declared_diamond.class_hash
        context.diamondCut = declare("./src/zkode/facets/upgradability/DiamondCut.cairo").class_hash
        context.erc721 = declare("./src/zkode/facets/token/erc721/ERC721.cairo").class_hash
        context.flobDb = declare("./src/zkode/facets/storage/flobdb/FlobDB.cairo").class_hash
        context.bootstrapper_class = declare("./src/bootstrap/Bootstrapper.cairo").class_hash
        context.starkshell = declare("./src/zkode/facets/starkshell/StarkShell.cairo").class_hash
        context.metadata = declare("./src/zkode/facets/metadata/metadata/UniversalMetadata.cairo").class_hash
    %}

    return ();
}

func deploy_bootstrapper() -> () {
    %{ context.bootstrapper_addr = deploy_contract("./src/bootstrap/Bootstrapper.cairo", [0]).contract_address %}

    return ();
}

func deploy_root{
    syscall_ptr: felt*, bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;
    local salt = 0;  // that is the salt which protostar uses
    local bootstrapper_addr;
    local bootstrapper_class;
    local diamond_class;
    %{
        ids.bootstrapper_addr = context.bootstrapper_addr
        ids.bootstrapper_class = context.bootstrapper_class
        ids.diamond_class = context.diamond
    %}

    let ch: ClassHash = get_class_hashes();
    let sel: Selector = get_selectors();

    local root;
    %{
        calldata = [0, 0, context.bootstrapper_class, context.feltmap]
        prepared_diamond =  prepare(declared=context.declared_diamond, constructor_calldata=calldata, salt=ids.salt)
        ids.root = prepared_diamond.contract_address
    %}

    let (facetCut_len, facetCut, calldata_len, calldata) = get_calldata(
        BrilliantBlocks, root, diamond_class, ch
    );

    local x = root;
    %{
        stop_prank_callable = start_prank(
            ids.BrilliantBlocks, target_contract_address=context.bootstrapper_addr
        )
    %}
    let (root) = IBootstrapper.deployRoot(
        bootstrapper_addr,
        salt,
        diamond_class,
        bootstrapper_class,
        ch.feltmap,
        facetCut_len,
        facetCut,
        calldata_len,
        calldata,
    );
    %{ stop_prank_callable() %}
    %{ context.root = ids.root %}

    local y = root;
    with_attr error_message("Precomputing address failed") {
        assert root = x;
    }

    return ();
}
