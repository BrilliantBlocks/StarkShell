from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE

from src.zklang.structs import Primitive, Variable, Instruction

func mintContract(_diamond_hash: felt, _erc721_hash: felt, _diamondCut_hash: felt) -> (
    res_len: felt, res: felt*
) {
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
    local diamondCut_primitive;
    local transferFrom_primitive;
    local transferFrom_calldata_var;

    %{
        from starkware.starknet.public.abi import get_selector_from_name

        ids.deploy_primitive = get_selector_from_name("__ZKLANG__DEPLOY")
        ids.felt_to_uint256_primitive = get_selector_from_name("__ZKLANG__FELT_TO_UINT256")
        ids.return_primitive = get_selector_from_name("__ZKLANG__RETURN")
        ids.noop_primitive = get_selector_from_name("__ZKLANG__NOOP")

        # facet primitive
        ids.mint_primitive = get_selector_from_name("mint")
        ids.diamondCut_primitive = get_selector_from_name("_diamondCut")
        ids.transferFrom_primitive = get_selector_from_name("transferFrom")

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
        ids.tokenId_var = get_selector_from_name("tokenId")
        ids.transferFrom_calldata_var = get_selector_from_name("transferFrom_calldata_var")
    %}

    tempvar NULLvar = Variable(0, 0, 0, 0);

    // Prepare deploy params
    tempvar instruction0 = Instruction(
        primitive=Primitive(0, noop_primitive),
        input1=Variable(diamond_hash_var, 0, 0, 0),
        input2=Variable(caller_address_var, 0, 0, 0),  // = salt
        output=Variable(deploy_cfg_var, 0, 0, 0),
        );

    // Prepare constructor calldata
    tempvar instruction1 = Instruction(
        primitive=Primitive(0, noop_primitive),
        input1=Variable(this_address_var, 0, 0, 0),
        input2=Variable(facet_key_var, 0, 0, 0),
        output=Variable(diamond_constructor_var, 0, 0, 0),
        );

    // Pop deploy_cfg var
    tempvar instruction2 = Instruction(
        primitive=Primitive(0, noop_primitive),
        input1=NULLvar,
        input2=Variable(deploy_cfg_var, 0, 0, 0),
        output=Variable(deploy_cfg_var, 0, 0, 0),
        );

    // deploy()
    tempvar instruction3 = Instruction(
        primitive=Primitive(0, deploy_primitive),
        input1=Variable(deploy_cfg_var, 0, 0, 0),
        input2=Variable(diamond_constructor_var, 0, 0, 0),
        output=Variable(diamond_addr_var, 0, 0, 0),
        );

    // convert address to token id
    tempvar instruction4 = Instruction(
        primitive=Primitive(0, felt_to_uint256_primitive),
        input1=Variable(diamond_addr_var, 0, 0, 0),
        input2=NULLvar,
        output=Variable(tokenId_var, 0, 0, 0),
        );

    // mint token for address
    tempvar instruction5 = Instruction(
        primitive=Primitive(_erc721_hash, mint_primitive),
        input1=Variable(caller_address_var, 0, 0, 0),
        input2=Variable(tokenId_var, 0, 0, 0),
        output=NULLvar,
        );

    // diamondCut() TODO delegate call
    tempvar instruction6 = Instruction(
        primitive=Primitive(_diamondCut_hash, diamondCut_primitive),
        input1=Variable(calldata_var, 0, 0, 0),
        input2=NULLvar,
        output=NULLvar,
        );

    // tempvar instruction7 = Instruction(
    //     primitive=Primitive(0, noop_primitive),
    //     input1=Variable(this_address_var, 0, 0, 0),
    //     input2=Variable(caller_address_var, 0, 0, 0),
    //     output=Variable(transferFrom_calldata_var, 0, 0, 0),
    //     );

    // tempvar instruction8 = Instruction(
    //     primitive=Primitive(0, noop_primitive),
    //     input1=Variable(tokenId_var, 0, 0, 0),
    //     input2=NULLvar,
    //     output=Variable(tokenId_var, 0, 0, 0),
    //     );

    // // transfer()
    // tempvar instruction9 = Instruction(
    //     primitive=Primitive(_erc721_hash, transferFrom_primitive),
    //     input1=Variable(transferFrom_calldata_var, 0, 0, 0),
    //     input2=Variable(tokenId_var, 0, 0, 0),
    //     output=NULLvar,
    //     );

    // return diamondAddress
    tempvar instruction7 = Instruction(
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
    tempvar deploy_cfg = Variable(deploy_cfg_var, 0, 0, 0);
    tempvar transferFrom_calldata = Variable(transferFrom_calldata_var, 0, 0, 0);

    tempvar memory_layout = (
        facet_key, 16, 0, 0,
        diamond_addr,
        tokenId,
        diamond_constructor_calldata,
        diamond_hash, _diamond_hash,
        deploy_cfg,
        transferFrom_calldata,
        );

    let instruction_len = 8 * Instruction.SIZE;
    let memory_layout_len = 7 * Variable.SIZE + facet_key.data_len + diamond_hash.data_len;
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
        memory_layout,
        );

    return (felt_code_len, felt_code);
}
