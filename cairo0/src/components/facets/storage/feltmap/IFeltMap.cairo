%lang starknet

@contract_interface
namespace IFeltMap {
    // / @selector 0x1f89a3afca1cd2076a205fe4fc46370aaed0c49f69700691b395a723e96acaf
    func registerElement(_element: felt) -> () {
    }

    // / @selector 0x34ea21e3feb6a55c5631f40cdf6d951f873a548a2eb398ea8f2ad9be519c25
    func resolveKey(_key: felt) -> (res_len: felt, res: felt*) {
    }

    // / @selector 0x2a5b44d6ee0a59c8c56c2e1fff32c18d3b87c4ec460920be3297c2355cec67f
    func calculateKey(_el_len: felt, _el: felt*) -> (res: felt) {
    }
}
