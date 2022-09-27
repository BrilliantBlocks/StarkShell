%lang starknet

@contract_interface
namespace IDiamondCut {
    func diamondCut(
        _address: felt, _facetCutAction: felt, _init: felt, _calldata_len: felt, _calldata: felt*
    ) -> () {
    }
}
