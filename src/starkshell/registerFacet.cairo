from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE

from src.zkode.facets.starkshell.structs import Primitive, Variable, Instruction

func registerFacet(_feltmap_class: felt) -> (res_len: felt, res: felt*) {
    alloc_locals;

    local assert_only_owner_keyword;
    local registerElement;
    local return_keyword;
    local var0_identifier;

    %{
        from starkware.starknet.public.abi import get_selector_from_name
        ids.assert_only_owner_keyword = get_selector_from_name("__ZKLANG__ASSERT_ONLY_OWNER")
        ids.registerElement = get_selector_from_name("registerElement")
        ids.return_keyword = get_selector_from_name("__ZKLANG__RETURN")
        ids.var0_identifier = get_selector_from_name("__ZKLANG__CALLDATA_VAR")
    %}

    tempvar NULLvar = Variable(0, 0, 0, 0);

    tempvar instruction0 = Instruction(
        Primitive(0, assert_only_owner_keyword),
        NULLvar,
        NULLvar,
        NULLvar,
        );

    tempvar instruction1 = Instruction(
        Primitive(_feltmap_class, registerElement),
        Variable(var0_identifier, 0, 0, 0),
        NULLvar,
        NULLvar,
        );

    tempvar instruction2 = Instruction(
        Primitive(0, return_keyword),
        NULLvar,
        NULLvar,
        NULLvar,
        );

    tempvar memory_layout = ();

    let instruction_len = 3 * Instruction.SIZE;
    let memory_layout_len = 0;
    let total_len = instruction_len + memory_layout_len + 1;
    let felt_code_len = total_len + 1;

    tempvar felt_code: felt* = new (
        total_len,
        instruction_len,
        instruction0,
        instruction1,
        instruction2,
        memory_layout,
        );

    return (felt_code_len, felt_code);
}
