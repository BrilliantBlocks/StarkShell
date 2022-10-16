%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

@storage_var
func owner_() -> (felt,) {
}

@event
func SetOwner(_owner: felt) {
}

namespace Ownership {
    func _get_owner_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
        let (owner) = owner_.read();
        return owner;
    }

    func _set_owner_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _owner: felt
    ) {
        owner_.write(_owner);
        SetOwner.emit(_owner);
        return ();
    }

    func _assert_only_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        let (caller) = get_caller_address();
        let (owner) = owner_.read();
        with_attr error_message("UNAUTHORIZED") {
            assert owner = caller;
        }
        return ();
    }
}
