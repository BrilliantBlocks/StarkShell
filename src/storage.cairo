%lang starknet


# @dev Store the address of the factory contract
# @return Address of its parent smart contract
@storage_var
func root() -> (res: felt):
end


# @dev Use bitmap of facet configuration in facet flyweight
# @return Bitmap
@storage_var
func facet_key() -> (res: felt):
end
