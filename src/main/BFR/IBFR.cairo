%lang starknet

@contract_interface
namespace IBFR {
    /// @selector 0x1f89a3afca1cd2076a205fe4fc46370aaed0c49f69700691b395a723e96acaf
    func registerElement(_element: felt) -> () {
    }

    /// @selector 0x3a0ee961d57284081ae38806062751e01756e9e9e17a6d14e80baa5095b602
    func registerElements(_elements_len: felt, _elements: felt*) -> () {
    }

    /// @selector 0x34ea21e3feb6a55c5631f40cdf6d951f873a548a2eb398ea8f2ad9be519c25
    func resolveKey(_key: felt) -> (res_len: felt, res: felt*) {
    }

    /// @selector 0x2a5b44d6ee0a59c8c56c2e1fff32c18d3b87c4ec460920be3297c2355cec67f
    func calculateKey(_el_len: felt, _el: felt*) -> (res: felt) {
    }

    /// @selector 0x2016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0
    func owner() -> (res: felt){
    }

    /// @selector 0x14a390f291e2e1f29874769efdef47ddad94d76f77ff516fad206a385e8995f
    func transferOwnership(_new_owner: felt) -> (){
    }

    /// @selector 0xd5d33d590e6660853069b37a2aea67c6fdaa0268626bc760350b590490feb5
    func renounceOwnership() -> (){
    }
}
