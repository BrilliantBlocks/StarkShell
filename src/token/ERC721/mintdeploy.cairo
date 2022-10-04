%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.starknet.common.syscalls import (
    deploy,
    get_block_number,
    get_caller_address,
    get_contract_address,
)
from starkware.cairo.common.math import assert_not_equal, split_felt
from starkware.cairo.common.uint256 import Uint256

from src.token.ERC721.ERC721 import _mint
from src.constants import FUNCTION_SELECTORS

@event
func MintDeploy(_tokenId: Uint256, _owner: felt, _facet_key: felt) {
}

@storage_var
func template() -> (res: felt) {
}

@external
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(_facet_key: felt) -> (
    res: felt
) {
    alloc_locals;

    let (owner) = get_caller_address();
    let (template_hash) = template.read();

    let (calldata_len, calldata) = assemleCalldata(owner, _facet_key);
    let diamond_address = deploy_diamond(template_hash, calldata_len, calldata);

    let (high, low) = split_felt(diamond_address);
    let token_id = Uint256(low, high);

    _mint(owner, token_id);
    MintDeploy.emit(token_id, owner, _facet_key);
    return (diamond_address,);
}


func assemleCalldata{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owner: felt, _facet_key: felt,
) -> (calldata_len: felt, calldata: felt*) {
    alloc_locals;

    let (root) = get_contract_address();

    let (local calldata: felt*) = alloc();
    assert calldata[0] = root;
    assert calldata[1] = owner;  // only required for root
    assert calldata[2] = _facet_key;
    assert calldata[3] = 0;  // _get_implementation_facet?

    return (4, calldata);
}


func deploy_diamond{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    class_hash: felt, constructor_calldata_len: felt, constructor_calldata: felt*,    
) -> felt {
    let (salt) = get_block_number();

    with_attr error_message("Diamond deployment failed") {
        let (diamond_address) = deploy(
            class_hash=class_hash,
            contract_address_salt=salt,
            constructor_calldata_size=constructor_calldata_len,
            constructor_calldata=constructor_calldata,
            deploy_from_zero=FALSE,
        );
    }

    return diamond_address;
}


@external
func __init_facet__{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _pool_type_class_hash: felt
) -> () {
    template.write(_pool_type_class_hash);

    return ();
}


@view
func __get_function_selectors__{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    ) -> (res_len: felt, res: felt*) {
    let (func_selectors) = get_label_location(selectors_start);
    return (res_len=1, res=cast(func_selectors, felt*));

    selectors_start:
    dw FUNCTION_SELECTORS.MINTDEPLOY.mint;
}


// @dev Support ERC-165
// @param interface_id
// @return success (0 or 1)
@view
func __supports_interface__(_interface_id: felt) -> (success: felt) {

    return (FALSE,);
}
