from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE

from src.zkode.starkshell.structs import Primitive, Variable, Instruction

func mintContract(_diamond_hash: felt, _erc721_hash: felt) -> (res_len: felt, res: felt*) {
    alloc_locals;
    local deploy_primitive;
    local mint_primitive;
    local return_primitive;
    local calldata_var;
    local this_address_var;
    local noop_primitive;
    local felt_to_uint256_primitive;
    local facet_key_var;
    local diamond_addr_var;
    local tokenId_var;
    local caller_address_var;
    local diamond_constructor_var;
    local deploy_cfg_var;
    local diamond_hash_var;
    local transferFrom_primitive;
    local transferFrom_var;
    local diamondCut_func;
    local diamondCut_var;
    local callContract_primitive;
    local sum_primitive;
    local balanceOf_primitive;
    local salt_var;

    %{
        from starkware.starknet.public.abi import get_selector_from_name

        # core primitives
        ids.deploy_primitive = get_selector_from_name("__ZKLANG__DEPLOY")
        ids.felt_to_uint256_primitive = get_selector_from_name("__ZKLANG__FELT_TO_UINT256")
        ids.return_primitive = get_selector_from_name("__ZKLANG__RETURN")
        ids.noop_primitive = get_selector_from_name("__ZKLANG__NOOP")
        ids.callContract_primitive = get_selector_from_name("__ZKLANG__CALL_CONTRACT")
        ids.sum_primitive = get_selector_from_name("__ZKLANG__SUM")

        # facet primitive
        ids.mint_primitive = get_selector_from_name("mint")
        ids.transferFrom_primitive = get_selector_from_name("_transferFrom")
        ids.balanceOf_primitive = get_selector_from_name("balanceOf")

        # external funcs Called
        ids.diamondCut_func = get_selector_from_name("diamondCut")

        # special vars
        ids.calldata_var = get_selector_from_name("__ZKLANG__CALLDATA_VAR")
        ids.this_address_var = get_selector_from_name("__ZKLANG__CONTRACT_ADDRESS_VAR")
        ids.caller_address_var = get_selector_from_name("__ZKLANG__CALLER_ADDRESS_VAR")


        # consts
        ids.facet_key_var = get_selector_from_name("facet_key_var")
        ids.diamond_hash_var = get_selector_from_name("diamond_hash_var")

        # helper vars
        ids.deploy_cfg_var = get_selector_from_name("deploy_cfg")
        ids.diamond_constructor_var = get_selector_from_name("diamond_constructor_var")
        ids.diamond_addr_var = get_selector_from_name("diamond_addr_var")
        ids.diamondCut_var = get_selector_from_name("diamondCut_var")
        ids.tokenId_var = get_selector_from_name("tokenId")
        ids.transferFrom_var = get_selector_from_name("transferFrom_var")
        ids.salt_var = get_selector_from_name("salt_var")
    %}

    tempvar NULLvar = Variable(0, 0, 0, 0);

    // balanceOf(caller)
    tempvar instruction0 = Instruction(
        primitive=Primitive(_erc721_hash, balanceOf_primitive),
        input1=Variable(caller_address_var, 0, 0, 0),
        input2=NULLvar,
        output=Variable(salt_var, 0, 0, 0),
        );

    // salt = sum(balance.low + balance.high)
    tempvar instruction1 = Instruction(
        primitive=Primitive(0, sum_primitive),
        input1=Variable(salt_var, 0, 0, 0),
        input2=NULLvar,
        output=Variable(salt_var, 0, 0, 0),
        );

    // salt = caller_address + salt
    tempvar instruction2 = Instruction(
        primitive=Primitive(0, sum_primitive),
        input1=Variable(salt_var, 0, 0, 0),
        input2=Variable(caller_address_var, 0, 0, 0),
        output=Variable(salt_var, 0, 0, 0),
        );

    // Prepare deploy params
    tempvar instruction3 = Instruction(
        primitive=Primitive(0, noop_primitive),
        input1=Variable(diamond_hash_var, 0, 0, 0),
        input2=Variable(salt_var, 0, 0, 0),
        output=Variable(deploy_cfg_var, 0, 0, 0),
        );

    // Prepare constructor calldata
    tempvar instruction4 = Instruction(
        primitive=Primitive(0, noop_primitive),
        input1=Variable(this_address_var, 0, 0, 0),
        input2=Variable(facet_key_var, 0, 0, 0),
        output=Variable(diamond_constructor_var, 0, 0, 0),
        );

    // Pop deploy_cfg var
    tempvar instruction5 = Instruction(
        primitive=Primitive(0, noop_primitive),
        input1=NULLvar,
        input2=Variable(deploy_cfg_var, 0, 0, 0),
        output=Variable(deploy_cfg_var, 0, 0, 0),
        );

    // deploy()
    tempvar instruction6 = Instruction(
        primitive=Primitive(0, deploy_primitive),
        input1=Variable(deploy_cfg_var, 0, 0, 0),
        input2=Variable(diamond_constructor_var, 0, 0, 0),
        output=Variable(diamond_addr_var, 0, 0, 0),
        );

    // convert address to token id
    tempvar instruction7 = Instruction(
        primitive=Primitive(0, felt_to_uint256_primitive),
        input1=Variable(diamond_addr_var, 0, 0, 0),
        input2=NULLvar,
        output=Variable(tokenId_var, 0, 0, 0),
        );

    // mint token for address
    tempvar instruction8 = Instruction(
        primitive=Primitive(_erc721_hash, mint_primitive),
        input1=Variable(this_address_var, 0, 0, 0),
        input2=Variable(tokenId_var, 0, 0, 0),
        output=NULLvar,
        );

    // diamond_address + diamondCut selector = diamondCut_var
    tempvar instruction9 = Instruction(
        primitive=Primitive(0, noop_primitive),
        input1=Variable(diamond_addr_var, 0, 0, 0),
        input2=Variable(diamondCut_func, 0, 0, 0),
        output=Variable(diamondCut_var, 0, 0, 0),
        );

    // pop()
    tempvar instruction10 = Instruction(
        primitive=Primitive(0, noop_primitive),
        input1=NULLvar,
        input2=Variable(diamondCut_var, 0, 0, 0),
        output=Variable(diamondCut_var, 0, 0, 0),
        );

    // push()
    tempvar instruction11 = Instruction(
        primitive=Primitive(0, noop_primitive),
        input1=Variable(calldata_var, 0, 0, 0),
        input2=NULLvar,
        output=Variable(calldata_var, 0, 0, 0),
        );

    // diamondCut_var + calldata = diamondCut_var
    tempvar instruction12 = Instruction(
        primitive=Primitive(0, noop_primitive),
        input1=Variable(diamondCut_var, 0, 0, 0),
        input2=Variable(calldata_var, 0, 0, 0),
        output=Variable(diamondCut_var, 0, 0, 0),
        );

    // pop()
    tempvar instruction13 = Instruction(
        primitive=Primitive(0, noop_primitive),
        input1=NULLvar,
        input2=Variable(diamondCut_var, 0, 0, 0),
        output=Variable(diamondCut_var, 0, 0, 0),
        );

    // IDiamond.diamondCut(diamondCut_var)
    tempvar instruction14 = Instruction(
        primitive=Primitive(0, callContract_primitive),
        input1=Variable(diamondCut_var, 0, 0, 0),
        input2=NULLvar,
        output=NULLvar,
        );

    // self + caller = transferFrom_var
    tempvar instruction15 = Instruction(
        primitive=Primitive(0, noop_primitive),
        input1=Variable(this_address_var, 0, 0, 0),
        input2=Variable(caller_address_var, 0, 0, 0),
        output=Variable(transferFrom_var, 0, 0, 0),
        );

    // pop()
    tempvar instruction16 = Instruction(
        primitive=Primitive(0, noop_primitive),
        input1=NULLvar,
        input2=Variable(transferFrom_var, 0, 0, 0),
        output=Variable(transferFrom_var, 0, 0, 0),
        );

    // transfer(transferFrom_var)
    tempvar instruction17 = Instruction(
        primitive=Primitive(_erc721_hash, transferFrom_primitive),
        input1=Variable(transferFrom_var, 0, 0, 0),
        input2=Variable(tokenId_var, 0, 0, 0),
        output=NULLvar,
        );

    // return diamondAddress
    tempvar instruction18 = Instruction(
        primitive=Primitive(0, return_primitive),
        input1=Variable(diamond_addr_var, 0, 0, 0),
        input2=NULLvar,
        output=NULLvar,
        );

    tempvar facet_key = Variable(facet_key_var, 0, 0, 3);
    tempvar diamond_addr = Variable(diamond_addr_var, 0, 0, 0);
    tempvar tokenId = Variable(tokenId_var, 0, 0, 0);
    tempvar diamond_constructor_calldata = Variable(diamond_constructor_var, 0, 0, 0);
    tempvar diamond_hash = Variable(diamond_hash_var, 0, 0, 1);
    tempvar diamondCut = Variable(diamondCut_func, 0, 0, 1);
    tempvar diamondCut_v = Variable(diamondCut_var, 0, 0, 0);
    tempvar deploy_cfg = Variable(deploy_cfg_var, 0, 0, 0);
    tempvar transferFrom_calldata = Variable(transferFrom_var, 0, 0, 0);
    tempvar salt = Variable(salt_var, 0, 0, 0);

    tempvar memory_layout = (
        facet_key, 16, 0, 0,  // TODO bug source 16 is diamondCut only
        diamond_addr,
        tokenId,
        diamond_constructor_calldata,
        diamond_hash, _diamond_hash,
        diamondCut, diamondCut_func,
        diamondCut_v,
        deploy_cfg,
        transferFrom_calldata,
        salt,
        );

    let instruction_len = 19 * Instruction.SIZE;
    let memory_layout_len = 10 * Variable.SIZE + facet_key.data_len + diamond_hash.data_len + diamondCut.data_len;
    let total_len = instruction_len + memory_layout_len + 1;
    let felt_code_len = total_len + 1;

    tempvar felt_code: felt* = new (
        total_len,
        instruction_len,
        instruction0,
        instruction1,
        instruction2,
        instruction3,
        instruction4,
        instruction5,
        instruction6,
        instruction7,
        instruction8,
        instruction9,
        instruction10,
        instruction11,
        instruction12,
        instruction13,
        instruction14,
        instruction15,
        instruction16,
        instruction17,
        instruction18,
        memory_layout,
        );

    return (felt_code_len, felt_code);
}
