%lang starknet
from src.zkode.diamond.structs import FacetCut

@contract_interface
namespace IBootstrapper {
    func deployRoot(
        _salt: felt,
        _diamond_class_hash: felt,
        _this_class_hash: felt,
        _feltmap_class_hash: felt,
        _facetCut_len: felt,
        _facetCut: FacetCut*,
        _calldata_len: felt,
        _calldata: felt*,
    ) -> (address: felt) {
    }

    func initRoot(
        _facetCut_len: felt, _facetCut: FacetCut*, _calldata_len: felt, _calldata: felt*
    ) -> () {
    }

    func precomputeRootAddress(
        _salt: felt,
        _diamond_class_hash: felt,
        _this_class_hash: felt,
        _feltmap_class_hash: felt,
        _facetCut_len: felt,
        _facetCut: FacetCut*,
        _calldata_len: felt,
        _calldata: felt*,
    ) -> (address: felt) {
    }
}
