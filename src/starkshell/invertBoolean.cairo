%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE

from src.zkode.starkshell.structs import Instruction, Primitive, Variable

func invertBoolean() -> (res_len: felt, res: felt*) {
    alloc_locals;
    local assert_only_owner_keyword;
    local branch_keyword;
    local set_function_keyword;
    local res_identifier;
    local return_keyword;
    local var0_identifier;
    local false_identifier;
    local true_identifier;
    local sentinel_selector;

    %{
        from starkware.starknet.public.abi import get_selector_from_name

        # core primitives
        ids.branch_keyword = get_selector_from_name("__ZKLANG__BRANCH")
        ids.return_keyword = get_selector_from_name("__ZKLANG__RETURN")

        # special vars
        ids.var0_identifier = get_selector_from_name("__ZKLANG__CALLDATA_VAR")
        ids.false_identifier = get_selector_from_name("__ZKLANG__FALSE_VAR")
        ids.true_identifier = get_selector_from_name("__ZKLANG__TRUE_VAR")

        # helper vars
        ids.sentinel_selector = get_selector_from_name("sentinel")
        ids.res_identifier = get_selector_from_name("res")
    %}

    tempvar NULLvar = Variable(0, 0, 0, 0);

    tempvar instruction0 = Instruction(
        Primitive(0, branch_keyword),
        Variable(var0_identifier, 0, 0, 0),
        Variable(sentinel_selector, 0, 0, 0),
        NULLvar,
        );

    tempvar instruction1 = Instruction(
        Primitive(0, return_keyword),
        Variable(false_identifier, 0, 0, 0),
        NULLvar,
        NULLvar,
        );

    tempvar instruction2 = Instruction(
        Primitive(0, return_keyword),
        Variable(true_identifier, 0, 0, 0),
        NULLvar,
        NULLvar,
        );

    tempvar sentinel_var = Variable(
        selector=sentinel_selector,
        protected=FALSE,
        type=0,
        data_len=2,
        );

    tempvar memory_layout = (
        sentinel_var, 1, 2,
        );

    let instruction_len = 3 * Instruction.SIZE;
    let memory_layout_len = 1 * Variable.SIZE + sentinel_var.data_len;
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
