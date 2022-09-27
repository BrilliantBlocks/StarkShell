%lang starknet

@contract_interface
namespace IRegistry {
    func register(_element: felt) -> () {
    }

    func resolve(_key: felt) -> (res_len: felt, res: felt*) {
    }

    func calculateKey(_el_len: felt, _el: felt*) -> (res: felt) {
    }
}
