%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE

from src.zklang.library import Function, Instruction, Primitive, Variable

func setZKLangFun() -> (res_len: felt, res: felt*) {
    alloc_locals;

    local assert_only_owner_keyword;
    local set_function_keyword;
    local return_keyword;
    local var0_identifier;

    %{
        from starkware.starknet.public.abi import get_selector_from_name
        ids.assert_only_owner_keyword = get_selector_from_name("__ZKLANG__ASSERT_ONLY_OWNER")
        ids.set_function_keyword = get_selector_from_name("__ZKLANG__SET_FUNCTION")
        ids.return_keyword = get_selector_from_name("__ZKLANG__RETURN")
        ids.var0_identifier = get_selector_from_name("__ZKLANG__CALLDATA_VAR")
    %}

    tempvar NULLvar = Variable(0, 0, 0, 0);

    tempvar instruction0 = Instruction(
        Primitive(0, assert_only_owner_keyword),
        NULLvar,
        NULLvar,
        );

    tempvar instruction1 = Instruction(
        Primitive(0, set_function_keyword),
        Variable(var0_identifier, 0, 0, 0),
        NULLvar,
        );

    tempvar instruction2 = Instruction(
        Primitive(0, return_keyword),
        NULLvar,
        NULLvar,
        );

    tempvar felt_code: felt* = new (
        3 * Instruction.SIZE,
        instruction0,
        instruction1,
        instruction2,
        );

    return (felt_code[0] + 1, felt_code);
}
