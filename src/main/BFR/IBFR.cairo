%lang starknet

@contract_interface
namespace IBFR {
    func registerElement(_element: felt) -> () {
    }

    func resolveKey(_key: felt) -> (res_len: felt, res: felt*) {
    }

    func calculateKey(_el_len: felt, _el: felt*) -> (res: felt) {
    }
}
