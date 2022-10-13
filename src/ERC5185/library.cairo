%lang starknet
from starkware.cairo.common.uint256 import Uint256


@event
func UpdateMetadata(tokenId: Uint256, type: felt, data_len: felt, data: felt*) {
}


namespace ERC5185 {
    func _update_metadata{syscall_ptr: felt*, range_check_ptr}(_tokenId: Uint256, _type: felt, _data_len: felt, _data: felt*) -> (){
        UpdateMetadata.emit(_tokenId, _type, _data_len, _data);
        return ();
    }
}
