%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE

from src.components.facets.starkshell.structs import Instruction, Primitive, Variable

func returnCalldata() -> (res_len: felt, res: felt*) {
    alloc_locals;

    local return_keyword;
    local var0_identifier;

    %{
        from starkware.starknet.public.abi import get_selector_from_name
        ids.return_keyword = get_selector_from_name("__ZKLANG__RETURN")
        ids.var0_identifier = get_selector_from_name("__ZKLANG__CALLDATA_VAR")
    %}

    tempvar NULLvar = Variable(0, 0, 0, 0);

    tempvar instruction0 = Instruction(
        Primitive(0, return_keyword),
        Variable(var0_identifier, 0, 0, 0),
        NULLvar,
        NULLvar,
        );

    tempvar memory_layout = ();

    let instruction_len = 1 * Instruction.SIZE;
    let memory_layout_len = 0;
    let total_len = instruction_len + memory_layout_len + 1;
    let felt_code_len = total_len + 1;

    tempvar felt_code: felt* = new (
        total_len,
        instruction_len,
        instruction0,
        memory_layout,
        );

    return (felt_code_len, felt_code);
}
