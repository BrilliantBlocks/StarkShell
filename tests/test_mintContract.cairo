%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin

from src.ERC2535.IDiamondCut import IDiamondCut
from src.ERC2535.IDiamond import IDiamond
from src.main.BFR.IBFR import IBFR
from src.main.TCF.ITCF import ITCF

from protostar.asserts import assert_eq, assert_not_eq


const BrilliantBlocks = 123;
const User = 456;

namespace FacetConfigKey {
    const OOO = 0;
    const OOI = 1;
    const OIO = 2;
    const OII = 3;
    const IOO = 4;
    const IOI = 5;
    const IIO = 6;
    const III = 7;
}

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    local BFR_address;
    local diamondCut_class_hash;
    local erc721_class_hash;
    %{
        ids.BFR_address = deploy_contract("./src/main/BFR/BFR.cairo", [ids.BrilliantBlocks]).contract_address
        context.diamond_class_hash = declare("./src/ERC2535/Diamond.cairo").class_hash
        ids.diamondCut_class_hash = declare("./src/ERC2535/DiamondCut.cairo").class_hash
        ids.erc721_class_hash = declare("./src/ERC721/ERC721.cairo").class_hash
        context.TCF_address = deploy_contract(
                "./src/main/TCF/TCF.cairo",
                [
                    context.diamond_class_hash,
                    ids.BFR_address,
                    0, # name
                    0, # symbol
                    1, # uri_len
                    1, # uri
                ],
            ).contract_address
        stop_prank_callable = start_prank(
            ids.BrilliantBlocks, target_contract_address=ids.BFR_address
        )
    %}
    let (local elements: felt*) = alloc();
    assert elements[0] = diamondCut_class_hash;
    assert elements[1] = erc721_class_hash;
    IBFR.registerElements(BFR_address, 2, elements);
    %{ stop_prank_callable() %}
    return ();
}

@external
func test_mintContract{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() {
    return ();
}
