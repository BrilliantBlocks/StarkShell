from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash_chain import hash_chain
from starkware.cairo.common.math import split_felt
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.uint256 import Uint256

from src.bootstrap.structs import ClassHash
from src.starkshell.setShellFun import setShellFun
from src.starkshell.mintContract import mintContract
from src.starkshell.registerFacet import registerFacet
from src.starkshell.updateMetadata import updateMetadata
from src.zkode.diamond.structs import FacetCut, FacetCutAction
from src.zkode.facets.starkshell.structs import Function

struct ERC721Calldata {
    receiver: felt,
    token_id_len: felt,  // 1
    token_id_low: felt,
    token_id_high: felt,
}

struct StarkShellCalldata {
    function0: Function,
    function1: Function,
    function2: Function,
    function3: Function,
}

struct DiamondCutCalldata {
    null: felt,
}

func get_calldata{pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _owner: felt, _root_address: felt, _diamond_hash: felt, _classes: ClassHash
) -> (facetCut_len: felt, facetCut: FacetCut*, calldata_len: felt, calldata: felt*) {
    alloc_locals;

    let (high, low) = split_felt(_root_address);
    let token_id = Uint256(low, high);

    let (setShellFun_compiled_len, setShellFun_compiled) = setShellFun();
    let (mintContract_compiled_len, mintContract_compiled) = mintContract(
        _diamond_hash, _classes.erc721
    );
    let (updateName_compiled_len, updateName_compiled) = updateMetadata();
    let (registerFacet_compiled_len, registerFacet_compiled) = registerFacet(_classes.feltmap);

    let (setShellFun_hash) = hash_chain{hash_ptr=pedersen_ptr}(setShellFun_compiled);
    let (mintContract_hash) = hash_chain{hash_ptr=pedersen_ptr}(mintContract_compiled);
    let (updateName_hash) = hash_chain{hash_ptr=pedersen_ptr}(updateName_compiled);
    let (registerFacet_hash) = hash_chain{hash_ptr=pedersen_ptr}(registerFacet_compiled);

    const setShellFun_selector = 0x1adb6ae929f40d0880cc53d4e03bcb65d131ce4bc0a37875753dd778d3b78d7;
    const mintContract_selector = 0x1881835aeeaa493c5f7836114d6e3f8dc2d53ea6ef4dece5e3e9ba3b021806;
    const updateName_selector = 0x19913e3386003e426925800083de8bc11547201d62a44eea7e39cefffcc021c;
    const registerFacet_selector = 0x8df66d1b7b73453a17ae01160e020e7b0e1f3cc261ad06a813ad616a280d5b;

    let facetCut_len = ClassHash.SIZE;
    tempvar facetCut: FacetCut* = cast(new (
        FacetCut(_classes.feltmap, FacetCutAction.Add),
        FacetCut(_classes.erc721, FacetCutAction.Add),
        FacetCut(_classes.starkshell, FacetCutAction.Add),
        FacetCut(_classes.diamondCut, FacetCutAction.Add),
        FacetCut(_classes.metadata, FacetCutAction.Add),
        FacetCut(_classes.flobDb, FacetCutAction.Add),
        ), FacetCut*);

    let tmp_len = (ClassHash.SIZE + 2) + (ERC721Calldata.SIZE + 1) + (StarkShellCalldata.SIZE + 2 + 10) + (DiamondCutCalldata.SIZE + 1) + 12;
    tempvar tmp = cast(new (
        ClassHash.SIZE + 1,
        ClassHash.SIZE,
        _classes.diamondCut,
        _classes.erc721,
        _classes.feltmap,
        _classes.flobDb,
        _classes.metadata,
        _classes.starkshell,
        ERC721Calldata.SIZE,
        ERC721Calldata(
            receiver=_owner,
            token_id_len=1,
            token_id_low=token_id.low,
            token_id_high=token_id.high,
            ),
        StarkShellCalldata.SIZE + 1 + 10,
        4,
        StarkShellCalldata(
            Function(setShellFun_selector, setShellFun_hash, 0),
            Function(mintContract_selector, mintContract_hash, 0),
            Function(updateName_selector, updateName_hash, 0),
            Function(registerFacet_selector, registerFacet_hash, 0),
            ),
        9,
        0,  // setShellFun params_len
        0,  // mintContract params_len
        5,  // updateNamedata params_len
        // ### Begin Variable ###
        465330906121207756919483712490106284233474427241768683713250428177289303613,
        0,
        0,
        1,
        722777708519828350460777408219631278991880314003707080813313655427100836380,
        // ### End Variable ###
        0,  // registerFacet params_len
        DiamondCutCalldata.SIZE,
        DiamondCutCalldata(0),
        // ### Metadata ###
        11,
        0,  // don't care
        0,  // don't care
        0,  // don't care
        4,  // https://m4chgvnjpozvm7p7jeo7vj3susfrkuencv6j5bf3u6mokcshjmeq.arweave.net/ZwRzVal7s1Z9_0kd-qdypIsVUI0VfJ6Eu6eY5QpHSwk
        184555836509371486644856095017587421344261193474617388276263770152936827443,
        203998027954878725543997547266317984232748597657159516903365148909254028897,
        202244606418614541364902086132942206699045874315590809968639424267107263609,
        10754949894223100254076072945295018243026244912222009195,
        FALSE,  // no infix
        0,  // no suffix
        0,  // don't care
        ), felt*);

    let (local calldata: felt*) = alloc();

    memcpy(calldata, tmp, tmp_len);
    let new_len = tmp_len;

    assert calldata[new_len] = 1 + setShellFun_compiled_len + mintContract_compiled_len + updateName_compiled_len + registerFacet_compiled_len + 1;
    let new_len = new_len + 1;

    assert calldata[new_len] = 4;
    let new_len = new_len + 1;

    // total array len
    assert calldata[new_len] = setShellFun_compiled_len + mintContract_compiled_len + updateName_compiled_len + registerFacet_compiled_len;
    let new_len = new_len + 1;

    // memcpy first_array
    memcpy(calldata + new_len, setShellFun_compiled, setShellFun_compiled_len);
    let new_len = new_len + setShellFun_compiled_len;

    // memcpy second array
    memcpy(calldata + new_len, mintContract_compiled, mintContract_compiled_len);
    let new_len = new_len + mintContract_compiled_len;

    // memcpy third array
    memcpy(calldata + new_len, updateName_compiled, updateName_compiled_len);
    let new_len = new_len + updateName_compiled_len;

    // memcpy fourth array
    memcpy(calldata + new_len, registerFacet_compiled, registerFacet_compiled_len);
    let new_len = new_len + registerFacet_compiled_len;

    let calldata_len = new_len;

    // return (facetCut_len, facetCut, calldata_len, calldata);
    return (facetCut_len, facetCut, calldata_len, calldata);
}
