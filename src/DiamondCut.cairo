%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.memcpy import memcpy
from starkware.starknet.common.syscalls import (
    get_caller_address,
    library_call,
    )

from src.structs import FacetCut
from src.IRegistry import IRegistry
from src.storage import facet_key, root


@event
func DiamondCut(
    _diamondCut_len: felt,
    _diamondCut: FacetCut*,
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
# @dev
# @return
@view
func facetAddresses{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }() -> (
        res_len: felt,
        res: felt*
    ):
    alloc_locals

    let (key) = facet_key.read()
    let (r) = root.read()
    let (f_len, f) = IRegistry.resolve(r, key)

    return (f_len, f)
end


# @dev
# @return
@view
func facetAddress{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(
        _functionSelector: felt,
    ) -> (
        res: felt,
    ):
    alloc_locals

    let (f_len, f) = facetAddresses()
    let (class_hash) = _facet_address(f_len, f, _functionSelector)

    return (class_hash)
end


func _facet_address{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(
        _facets_len: felt,
        _facets: felt*,
        _functionSelector: felt,
    ) -> (
        res: felt,
    ):
    alloc_locals

    if _facets_len == 0:
        return (0)
    end

    let (selectors_len: felt, selectors: felt*) = facetFunctionSelectors(_facets[0])

    let (is_implemented) = _is_implemented(selectors_len, selectors, _functionSelector)

    if is_implemented == TRUE:
        return (_facets[0])
    end

    return _facet_address(
        _facets_len - 1,
        _facets + 1,
        _functionSelector,
        )
    end


func _is_implemented{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(
        _selectors_len: felt,
        _selectors: felt*,
        _functionSelector: felt,
    ) -> (
        res: felt,
    ):
    
    if _selectors_len == 0:
        return (FALSE)
    end

    if _selectors[0] == _functionSelector:
        return (TRUE)
    end

    return _is_implemented(
        _selectors_len - 1,
        _selectors + 1,
        _functionSelector
        )
end


# @dev
# @return
@view
func facetFunctionSelectors{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(
        _facet: felt,
    ) -> (
        res_len: felt,
        res: felt*,
    ):
    alloc_locals

    let no_param_len = 0
    let (local no_param: felt*) = alloc()

    let (r_len, r) = library_call(
        class_hash=_facet,
        function_selector=0x3cc1ae64595e4bc082d3fd1ef7b6792d5d08143d44bbaf4ac96c3bcab576099, # getFunctionSelectors
        calldata_size=no_param_len,
        calldata=no_param,
    )

    return (r_len, r)
end


# @dev what purpose in implementing if the resulting datastructure is not possible
# @return
@view
func facets{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }() -> (
        res_len: felt,
        res: felt*,
    ):

    return facetAddresses()
end
