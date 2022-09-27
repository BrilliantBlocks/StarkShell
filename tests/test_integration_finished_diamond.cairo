%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

from protostar.asserts import assert_eq

// # @external
// # func __setup__{
// #         syscall_ptr : felt*,
// #         pedersen_ptr : HashBuiltin*,
// #         range_check_ptr,
// #     }() -> ():
// #     %{
// #         diamond_loupe_hash = declare("./src/DiamondLoupe.cairo").class_hash
// #         registry_hash = declare("./src/Register.cairo").class_hash
// #         # TODO declare erc-721
// #         # TODO declare mint and factory
// #         context.diamond_address = deploy_contract(
// #                 "./src/Diamond.cairo",
// #                 [
// #                     0,  # A root diamond has no parent
// #                     14,  # Register, diamond loupe, ERC-721, mint, factory
// #                 ],
// #             ).contract_address
// #     %}
// #
// #     return ()
// # end
// #
// #
// # @external
// # func test_facetAddresses{
// #         syscall_ptr : felt*,
// #         pedersen_ptr : HashBuiltin*,
// #         range_check_ptr,
// #     }():
// #
// #     return ()
// # end
