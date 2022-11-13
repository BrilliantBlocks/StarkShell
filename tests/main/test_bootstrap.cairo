%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.ERC1155.IERC1155 import TokenBatch
from src.ERC2535.IDiamond import IDiamond
from src.ERC2535.IDiamondCut import FacetCut, FacetCutAction, IDiamondCut
from src.ERC1155.IERC1155 import IERC1155
from src.ERC2535.Init import IRootDiamondFactory, ClassHash
from src.ERC721.IERC721 import IERC721
from src.main.BFR.IBFR import IBFR
from src.main.TCF.ITCF import ITCF
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
        context.mintContract = get_selector_from_name("mintContract")
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
        print(context.diamond)
        print(context.erc721)
    %}

    return ();
}

func deployRootDiamondFactory() -> () {
    %{ context.rootFactory = deploy_contract("./src/ERC2535/Init.cairo", []).contract_address %}

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
    let (rootDiamond) = IRootDiamondFactory.deployRootDiamond(
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
func test_getRoot_returns_rootAddress{
    syscall_ptr: felt*, bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    let addr: Address = getAddresses();

    let (root: felt) = IDiamond.getRoot(addr.rootDiamond);
    assert_eq(root, addr.rootDiamond);

    return ();
}

@external
func test_facets_returns_five_class_hashes{
    syscall_ptr: felt*, bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    let addr: Address = getAddresses();

    let (facets_len, _) = IDiamond.facets(addr.rootDiamond);
    assert_eq(facets_len, 5);

    return ();
}

@external
func test_getFacetFunctionSelectors_returns_two_functions_for_zklang{
    syscall_ptr: felt*, bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    let addr: Address = getAddresses();
    let ch: ClassHash = getClassHashes();

    let (fun_len, _) = IDiamond.facetFunctionSelectors(addr.rootDiamond, ch.zklang);
    assert_eq(fun_len, 2);

    return ();
}

@external
func test_getImplementation_returns_erc721_hash{
    syscall_ptr: felt*, bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    let ch: ClassHash = getClassHashes();
    let addr: Address = getAddresses();

    let (implementation: felt) = IDiamond.getImplementation(addr.rootDiamond);
    assert_eq(implementation, ch.erc721);

    return ();
}

struct ERC721Calldata {
    receiver: felt,
    tokenId_len: felt,  // 2
    tokenId0: Uint256,
    tokenId1: Uint256,
}

@external
func test_mintContract{
    syscall_ptr: felt*, bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    let addr: Address = getAddresses();
    let ch: ClassHash = getClassHashes();
    let (local NULLptr: felt*) = alloc();
    let (local FCNULLptr: FacetCut*) = alloc();
    const NULL = 0;

    let facetCut_len = 1;
    tempvar facetCut = new FacetCut(ch.erc721, FacetCutAction.Add);

    let calldata_len = ERC721Calldata.SIZE;
    let calldata_len = ERC721Calldata.SIZE + 1;
    tempvar calldata = new (
        ERC721Calldata.SIZE,
        ERC721Calldata(
            receiver=User,
            tokenId_len=2,
            tokenId0=Uint256(1, 0),
            tokenId1=Uint256(3, 0),
            ),
        );
    %{
        stop_prank_callable = start_prank(
            ids.User, target_contract_address=context.rootDiamond
        )
    %}
    let (diamond_address) = ITCF.mintContract(
        addr.rootDiamond, 1, facetCut, calldata_len, calldata
    );
    // let (diamond_address) = ITCF.mintContract(addr.rootDiamond, NULL, FCNULLptr, NULL, NULLptr);
    %{ stop_prank_callable() %}

    assert_not_eq(diamond_address, 0);

    let (root) = IDiamond.getRoot(diamond_address);
    assert_eq(root, addr.rootDiamond);

    // %{
    //     stop_prank_callable = start_prank(
    //         ids.User, target_contract_address=ids.diamond_address
    //     )
    // %}
    // IDiamondCut.diamondCut(diamond_address, facetCut_len, facetCut, calldata_len, calldata);
    // %{ stop_prank_callable() %}

    // Assert that initialzation yields expected token for user
    let (owner: felt) = IERC721.ownerOf(diamond_address, Uint256(1, 0));
    assert_eq(owner, User);

    let (owner: felt) = IERC721.ownerOf(diamond_address, Uint256(3, 0));
    assert_eq(owner, User);

    let (facets_len, _) = IDiamond.facets(diamond_address);
    assert_eq(facets_len, 2);

    return ();
}
