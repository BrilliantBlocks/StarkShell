%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import call_contract


@storage_var
func proxy_target_() -> (res: felt) {
}


namespace Proxy {

    func _proxy{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(_selector: felt, _calldata_size: felt, _calldata: felt*) -> (retdata_size: felt, retdata: felt*) {
        let (proxy_target) = proxy_target_.read();
        let (retdata_size: felt, retdata: felt*) = call_contract(
            contract_address=proxy_target, function_selector=_selector, calldata_size=_calldata_size, calldata=_calldata
        );
        return (retdata_size, retdata);
    }

    func _set_proxy_target_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_address: felt) {
        proxy_target_.write(_address);
        return ();
    }

    func _get_proxy_target_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
        let (address) = proxy_target_.read();
        return address;
    }

}
