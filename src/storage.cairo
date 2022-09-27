%lang starknet

// @dev Store the address of the factory contract
// @return Address of its parent smart contract
@storage_var
func root() -> (res: felt) {
}

// @dev Store the address of the facet registry contract
// @return Address of registry
@storage_var
func registry() -> (res: felt) {
}

// @dev Use bitmap of facet configuration in facet flyweight
// @return Bitmap
@storage_var
func facet_key() -> (res: felt) {
}

// @dev Map bit to element
// @param id in bitmap
// @return element
@storage_var
func bitmap(_bitId: felt) -> (res: felt) {
}
