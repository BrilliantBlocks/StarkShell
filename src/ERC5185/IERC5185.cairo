%lang starknet
from starkware.cairo.common.uint256 import Uint256


/// @selector 0x26008cce4e65b7effced27d90009550257d25d0b5c8cd9d7d06e61e26dea6de
@event
func UpdateMetadata(tokenId: Uint256, type: felt, data_len: felt, data: felt*) {
}

@contract_interface
namespace ERC5185 {
    /// @selector 0xd1df127d90a37687d0a986a667f4f88eebc4437582fa7bff7d6955ab689037
    func updateMetadata(_tokenId: Uint256, _type: felt, _data_len: felt, _data: felt*) -> (){
    }
}
