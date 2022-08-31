%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import (
        get_caller_address,
        get_contract_address,
        library_call,
    )
from src.constants import (
        IERC165_ID,
        IERC20_ID,
        IERC721_ID,
        IERC1155_ID,
        IERC5114_ID,
        FUNCTION_SELECTORS,
    )
from src.ERC2535.DiamondLoupe import (
        facetAddress,
        facetAddresses,
        facetFunctionSelectors,
        facets,
    )
from src.storage import facet_key, root
from src.token.ERC721.ERC721 import _mint
from src.FacetRegistry.IRegistry import IRegistry


# @dev
# @param _root: Address of deploying contract
@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(
        _root: felt,
        _facet_key: felt,
    ):
        facet_key.write(_facet_key)
        root.write(_root)
        
        if _root == 0:
            let (caller) = get_caller_address()
           _mint(caller, Uint256(0,0))
            return ()
        end

        return ()
end


# @dev
# @param
# @return
@external
@raw_input
@raw_output
func __default__{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    }(
        selector: felt,
        calldata_size: felt,
        calldata: felt*
    ) -> (
        retdata_size: felt,
        retdata: felt*
    ):
    
    let (facet: felt) = facetAddress(selector)

    let (retdata_size: felt, retdata: felt*) = library_call(
        class_hash=facet,
        function_selector=selector,
        calldata_size=calldata_size,
        calldata=calldata
    )

    return (retdata_size=retdata_size, retdata=retdata)
end


# @dev Support ERC-165
# @param interface_id
# @return success (0 or 1)
@view
func supportsInterface{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(
        interface_id: felt
    ) -> (
        res: felt
    ):
    alloc_locals
    if interface_id == IERC165_ID:
        return (TRUE)
    end

    let (facets_len, facets) = facetAddresses()

    return _supportsInterface(interface_id, facets_len, facets)
end


# @dev
# @return
func _supportsInterface{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(
        interface_id: felt,
        facets_len: felt,
        facets: felt*,
    ) -> (
        res: felt,
    ):
    alloc_locals
    if facets_len == 0:
        return (FALSE)
    end

    let (facet_supports_interface: felt) = _supportsInterfaceLibrary(interface_id, facets[0])

    if facet_supports_interface == TRUE:
        return (TRUE)
    end

    return _supportsInterface(
        interface_id,
        facets_len - 1,
        facets + 1,
    )
end


func _find_token_facet{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(
        facets_len: felt,
        facets: felt*,
    ) -> (
        res: felt,
    ):
    if facets_len == 0:
        return (FALSE)
    end

    let (is_erc20_facet: felt) = _supportsInterfaceLibrary(IERC20_ID, facets[0])
    if is_erc20_facet == TRUE:
        return (facets[0])
    end

    let (is_erc721_facet: felt) = _supportsInterfaceLibrary(IERC721_ID, facets[0])
    if is_erc721_facet == TRUE:
        return (facets[0])
    end

    let (is_erc1155_facet: felt) = _supportsInterfaceLibrary(IERC1155_ID, facets[0])
    if is_erc1155_facet == TRUE:
        return (facets[0])
    end

    let (is_erc5114_facet: felt) = _supportsInterfaceLibrary(IERC5114_ID, facets[0])
    if is_erc5114_facet == TRUE:
        return (facets[0])
    end

    return _find_token_facet(
        facets_len - 1,
        facets + 1,
    )
end


func _supportsInterfaceLibrary{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        _interface_id: felt,
        _facet: felt,
    ) -> (
        res: felt,
    ):
    alloc_locals

    let (local param: felt*) = alloc()
    assert param[0] = _interface_id

    let (r_len, r) = library_call(
        class_hash=_facet,
        function_selector=FUNCTION_SELECTORS.ERC165.supportsInterface,
        calldata_size=1,
        calldata=param,
    )

    return (r[0])
end


# @dev Aspect requires this function for token type detection
# @notice The respective facet must be included at deploy time
# @return Class hash of token type. Return 0 if no token is included
@view
func getImplementation{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    }() -> (
        res: felt
    ):

    let (facets_len, facets) = facetAddresses()

    return _find_token_facet(facets_len, facets)
end
