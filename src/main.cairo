%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
        get_caller_address,
        get_contract_address,
        library_call,
    )


# @dev Store the address of the factory contract
# @return Address of its parent smart contract
@storage_var
func root() -> (res: felt):
end


# @param _root: Address of deploying contract
@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        _root: felt,
    ):
        root.write(_root)

        return ()
end
