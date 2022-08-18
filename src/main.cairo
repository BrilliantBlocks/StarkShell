%lang starknet
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
        get_caller_address,
        get_contract_address,
        library_call,
    )

from src.StorageVars import facet_key, root

# @dev
# @param _root: Address of deploying contract
@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(
        _root: felt,
    ):
        root.write(_root)

        return ()
end


# # @dev
# # @param
# # @return
# @external
# @raw_input
# @raw_output
# func __default__{
#         syscall_ptr: felt*,
#         pedersen_ptr: HashBuiltin*,
#         range_check_ptr
#     }(
#         selector: felt,
#         calldata_size: felt,
#         calldata: felt*
#     ) -> (
#         retdata_size: felt,
#         retdata: felt*
#     ):
# 
#     let (facet: felt) = find_matching_facet(my_facets_len, my_facets)
# 
#     let (retdata_size: felt, retdata: felt*) = library_call(
#         class_hash=facet,
#         function_selector=selector,
#         calldata_size=calldata_size,
#         calldata=calldata
#     )
# 
#     return (retdata_size=retdata_size, retdata=retdata)
# end


# @dev Support ERC-165
# @param interface_id
# @return success (0 or 1)
@view
func supportsInterface{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(
        interface_id: felt
    ) -> (
        success: felt
    ):

        let IERC165_ID = 0x01ffc9a7

        if interface_id == IERC165_ID:
            return (TRUE)
        end

        return (FALSE)
end
