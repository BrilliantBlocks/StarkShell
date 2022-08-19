%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.memcpy import memcpy
from starkware.starknet.common.syscalls import (
    get_caller_address,
    library_call,
    )

from src.storage import facet_key, root
from src.IRegistry import IRegistry
from src.DiamondLoupe import facetAddresses, facetAddress


@event
func DiamondCut(
    _address: felt,
    _facetCutAction: felt,
    _init: felt,
    _calldata_len: felt,
    _calldata: felt*
    ):
end


@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(
       _root: felt,
       _facet_key: felt,
    ):
       root.write(_root)
       facet_key.write(_facet_key)

       return ()
end


# @dev
# @return
@external
func diamondCut{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(
        _address: felt,
        _facetCutAction: felt,
        _init: felt,
        _calldata_len: felt,
        _calldata: felt*,
    ) -> ():
    # TODO access control

    if _facetCutAction == 0:
        _add_facet(_address, _init, _calldata_len, _calldata)
    else:
        _remove_facet(_address)
    end

    return ()
end


func _add_facet{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
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

    assert facets[facets_len] = _address
    let (new_key) = IRegistry.calculateKey(r, facets_len + 1, facets)
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
    memcpy(dst=ptr + x, src=facets + x, len=facets_len -x)
    let (new_key) = IRegistry.calculateKey(r, facets_len + 1, ptr)
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
