%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.math import split_felt
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    library_call,
    )
from starkware.cairo.common.registers import get_label_location

from src.constants import (
        FUNCTION_SELECTORS,
        IDIAMONDCUT_ID,
    )
from src.storage import facet_key, root
from src.token.ERC721.IERC721 import IERC721
from src.FacetRegistry.IRegistry import IRegistry
from src.ERC2535.DiamondLoupe import facetAddresses, facetAddress


@event
func DiamondCut(
    _address: felt,
    _facetCutAction: felt,
    _init: felt,
    _calldata_len: felt,
    _calldata: felt*
    ):
end


# Enum
struct FacetCutAction:
    member Add: felt
    member Replace: felt
    member Remove: felt
end


# @dev
# @return
@external
func diamondCut{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(
        _address: felt,
        _facetCutAction: felt,
        _init: felt,
        _calldata_len: felt,
        _calldata: felt*,
    ) -> ():
    let (r) = root.read()
    let (self) = get_contract_address()
    let (low, high) = split_felt(self)
    let (caller) = get_caller_address()

    # is root diamond
    if r == 0:
        let (owner) = IERC721.ownerOf(self, Uint256(0,0))
    else:
        let (owner) = IERC721.ownerOf(r, Uint256(low, high))
    end

    with_attr error_message("YOU MUST BE THE OWNER TO CALL THE FUNCTION"):
        assert caller = owner
    end

    if _facetCutAction == FacetCutAction.Add:
        _add_facet(_address, _init, _calldata_len, _calldata)
        return ()
    else:
        _remove_facet(_address)
        return ()
    end

end


func _add_facet{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(
        _address: felt,
        _init: felt,
        _calldata_len: felt,
        _calldata: felt*,
    ) -> ():
    alloc_locals

    let (key) = facet_key.read()
    let (r) = root.read()

    let (facets_len, facets) = facetAddresses()

    # Write facet to next free slot
    assert facets[facets_len] = _address

    # is root diamond
    if r == 0:
        let (self) = get_contract_address()
        let (new_key) = IRegistry.calculateKey(self, facets_len + 1, facets)
    else:
        let (new_key) = IRegistry.calculateKey(r, facets_len + 1, facets)
    end

    facet_key.write(new_key)

    if _init == 0:
        return ()
    end

    library_call(
        class_hash=_address,
        function_selector=0x239ae22f052839d1eee46be543e9729fe75a8342c18f8d74b80ea7779426c2e, # initFacet
        calldata_size=_calldata_len,
        calldata=_calldata,
    )

    return ()
end


func _remove_facet{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(
        _address: felt,
    ) -> ():
    alloc_locals

    let (key) = facet_key.read()
    let (r) = root.read()

    let (facets_len, facets) = facetAddresses()

    # find it
    let (x) = _remove_facet_helper(facets_len, facets, _address, 0)
    let (local ptr: felt*) = alloc()
    memcpy(dst=ptr, src=facets, len=x)

    # if non-tail element is removed
    if facets_len != x + 1:
        memcpy(dst=ptr + x, src=facets + x + 1, len=facets_len-x-1) # TODO
    end

    if r != 0:
        let (new_key) = IRegistry.calculateKey(r, facets_len - 1, ptr)
    else:
        let (my_root) = get_contract_address()
        let (new_key) = IRegistry.calculateKey(my_root, facets_len - 1, ptr)
    end

    facet_key.write(new_key)

    return ()
end


func _remove_facet_helper{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(
        _f_len: felt,
        _f: felt*,
        _target: felt,
        _id: felt,
    ) -> (res: felt):
    if _f_len == 0:
        with_attr error_message("FACET DOES NOT EXIST"):
            assert 1 = 0
        end
    end
    if _target == _f[0]:
        return (_id)
    end

    return _remove_facet_helper(
        _f_len - 1,
        _f + 1,
        _target,
        _id + 1,
    )
end


@external
func __init_facet__{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr : felt*,
        range_check_ptr,
    }() -> ():

    return ()
end


@view
func __get_function_selectors__{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr : felt*,
        range_check_ptr,
    }() -> (
        res_len: felt,
        res: felt*,
    ):
    let (func_selectors) = get_label_location(selectors_start)
    return (res_len = 1, res=cast(func_selectors, felt*))

    selectors_start:
    dw FUNCTION_SELECTORS.diamondCut
end


# @dev Support ERC-165
# @param interface_id
# @return success (0 or 1)
@view
func __supports_interface__{
# TODO remove implicit arguments?
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(
        _interface_id: felt
    ) -> (
        success: felt
    ):

    if _interface_id == IDIAMONDCUT_ID:
        return (TRUE)
    end

    return (FALSE)
end