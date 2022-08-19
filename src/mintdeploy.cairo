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

from src.ERC721 import _mint
from src.constants import FUNCTION_SELECTORS


@event
func MintDeploy(
    _tokenId: Uint256, 
    _owner: felt,
    _facet_key: felt,
    ):
end


@storage_var
func template() -> (res: felt):
end


@external
func mint{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr : felt*,
        range_check_ptr,
    }(
        _facet_key : felt
    ) -> (
        res: felt
    ):
    alloc_locals

    let (owner) = get_caller_address()
    let (root) = get_contract_address()
    let (salt) = get_block_number()
    let (template_hash) = template.read()

    let calldata_len = 2
    let (local calldata: felt*) = alloc()
    assert calldata[0] = root
    assert calldata[1] = _facet_key

    with_attr error_message("Pool deployment failed"):
        let (pool_address) = deploy(
            class_hash                = template_hash,
            contract_address_salt     = salt,
            constructor_calldata_size = calldata_len,
            constructor_calldata      = calldata,
            deploy_from_zero          = FALSE
        )
    end

    let (high, low) = split_felt(pool_address)
    let token_id = Uint256(low, high)

    _mint(self, owner, token_id)
    MintDeploy.emit(token_id, owner,_facet_key)
    return (pool_address)
end


@external
func __init_facet__{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr : felt*,
        range_check_ptr,
    }(
        _pool_type_class_hash: felt
    ) -> ():
    template.write(_pool_type_class_hash)

    return ()
end


@view
func __get_function_selectors__{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr : felt*,
        range_check_ptr,
    }() -> (res_len: felt, res: felt):
    let (func_selectors) = get_label_location(selectors_start)
    return (res_len = 1, data=cast(func_address, felt*))

    selectors_start:
    dw FUNCTION_SELECTORS.mint
end
