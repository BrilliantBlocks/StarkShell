%lang starknet

@contract_interface
namespace IFlobDB {
    func store(_data_len: felt, _data: felt*) -> (res: felt) {
    }

    func load(_hash: felt) -> (res_len: felt, res: felt*) {
    }

    func loadCell(_hash: felt, _offset: felt) -> (res: felt) {
    }

    func loadRange(_hash: felt, _offset_start: felt, _offset_end: felt) -> (
        res_len: felt, res: felt*
    ) {
    }
}
