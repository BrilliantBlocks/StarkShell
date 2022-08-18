%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin

from protostar.asserts import (
        assert_eq,
    )

from src.DiamondCut import diamondCut, facetAddresses
from src.IRegistry import IRegistry


@contract_interface
namespace IDiamondLoupe:
    func facetAddresses() -> (res_len: felt, res: felt*):
    end
end


@external
func __setup__{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }() -> ():
    alloc_locals

    local registry_address: felt
    %{
        ids.registry_address = deploy_contract("./src/Facets.cairo").contract_address
        context.diamondCut_address = deploy_contract("./src/DiamondCut.cairo", [ids.registry_address, 15]).contract_address
    %}

    IRegistry.register(registry_address, 0xA)
    IRegistry.register(registry_address, 0xB)
    IRegistry.register(registry_address, 0xC)
    IRegistry.register(registry_address, 0xD)

    return ()
end


@external
func test_facetAddresses{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }():
    tempvar diamondCut_address
    %{
        ids.diamondCut_address = context.diamondCut_address
    %}
    let (f_len, f) = IDiamondLoupe.facetAddresses(diamondCut_address)

    assert_eq(f_len, 4)

    return ()
end
