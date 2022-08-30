%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import library_call

from src.constants import(
        FUNCTION_SELECTORS,
    )
from src.storage import facet_key, root
from src.IRegistry import IRegistry


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
        function_selector=FUNCTION_SELECTORS.getFunctionSelectors,
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
