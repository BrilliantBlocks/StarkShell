%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import split_felt
from starkware.starknet.common.syscalls import deploy, get_block_timestamp

from src.TCF.Factory.IFactory import DeployContract

@storage_var
func contract_hash_() -> (felt) {
}


namespace Factory {

    func _set_contract_hash_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_contract_hash: felt) {
        contract_hash_.write(_contract_hash);
        return ();
    }

    func _get_contract_hash_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt{
        let (contract_hash) = contract_hash_.read();
        return contract_hash;
    }

    func _deploy_contract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_constructor_calldata_len: felt, _constructor_calldata: felt*) -> felt {
        alloc_locals;
        let (salt) = get_block_timestamp();
        let (class_hash) = contract_hash_.read();
        with_attr error_message("FAILED DEPLOYMENT") {
            let (contract_address) = deploy(
                class_hash=class_hash,
                contract_address_salt=salt,
                constructor_calldata_size=_constructor_calldata_len,
                constructor_calldata=_constructor_calldata,
                deploy_from_zero=FALSE,
            );
        }
        DeployContract.emit(contract_address, _constructor_calldata_len, _constructor_calldata);
        return contract_address;
    }

}
