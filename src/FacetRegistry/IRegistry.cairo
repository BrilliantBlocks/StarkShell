%lang starknet


@contract_interface
namespace IRegistry:
    func register(_element: felt) -> ():
    end

    func resolve(_key: felt) -> (res_len: felt, res: felt*):
    end

    func calculateKey(_el_len: felt, _el: felt*) -> (res: felt):
    end
end
