%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE

from src.zklang.library import Function, Instruction, Primitive, Variable

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
        );

    tempvar felt_code: felt* = new (
        1 * Instruction.SIZE,
        instruction0,
        );

    return (felt_code[0] + 1, felt_code);
}
