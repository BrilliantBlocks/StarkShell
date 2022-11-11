const ALL_ONES = 2 ** 251 - 1;
const NULL = 0;
const IERC165_ID = 0x01ffc9a7;

const IERC20_ID = 0x36372b07;
const IERC20_METADATA_ID = 0x942e8b22;
const IERC721_ID = 0x80ac58cd;
const IERC721_METADATA_ID = 0x5b5e139f;
const IERC721_RECEIVER_ID = 0x150b7a02;
const IERC1155_ID = 0xd9b67a26;
const IERC1155_METADATA_ID = 0x0e89341c;
const IERC5114_ID = 0x0fb8a782;
const IERC5114_METADATA_ID = 0x6cea869c;

const IERC2981_ID = 0x2a55205a;
const IERC4906_ID = 0x49064906;
const IERC5007_ID = 0x7a0cdf92;
const IERC4907_ID = 0xad092b5c;
const IERC4675_ID = 0x83f5d35f;
const IERC5185_ID = 0x00000001;  // TODO
const IACCOUNT_ID = 0xf10dbd44;
const IDIAMONDLOUPE_ID = 0x123;  // TODO
const IDIAMONDCUT_ID = 0x123;  // TODO
const FEE_DENOMINATOR = 10000;

namespace API {
    namespace CORE {
        const __ZKLANG__ADD = 0x33fbf27d4be7e5f658249feea1d097ea59bfd94cd7a3d7d4bc9d435f945d1b1;
        const __ZKLANG__RETURN = 0x1260326d98aa121b333202d173c639e6c5f6866412b05147c803baecdd17985;
        const __ZKLANG__EVENT = 0x315c4e503b7f8705e10f5e48d4899db38942f0874c59e0debd029d0e1dd9a26;
        const __ZKLANG__BRANCH = 0xce691f9bc53c77ba4a888fec927f8beb04746d9f4256b40c4566af3a100ea5;
        const __ZKLANG__REVERT = 0x28089cf47fb4b74d7ca26ab7ac970b2dc2b1bd4ed7dc25ca96784bc366a815f;
        const __ZKLANG__CALLDATA_VAR = 0x3c6f3599ac37319bbc36d2acb3ea0b2567cdbe7fd6ed09616db6414f36bdc40;
        const __ZKLANG__SET_FUNCTION = 0x18ae100d40c97134a859d0645d6b26e9c64a971383a16c41bc2aa306cd97972;
        const __ZKLANG__EXEC = 0x1420ce4716273931c8d8177eb8b3996fafbf893270232b06f31b5189858987b;
        const __ZKLANG__ASSERT_ONLY_OWNER = 0x39549628361e8cbb303e3c959c8576de71ccf55f61a66b77e3067f0d3d7c90c;
        const __ZKLANG__CALLER_ADDRESS_VAR = 0x322f3db6714056d8d260dfc87d0ebe50e764b25f536f9aea41d6544f025077b;
        const __ZKLANG__CONTRACT_ADDRESS_VAR = 0x3b6b7fdff7b925dac637ced22595f8b097b895737f63123221f0e4ec0c89242;
    }
}

namespace FUNCTION_SELECTORS {
    namespace STORAGE {
        const store = 0x1d88711b08bdcd7556c5d2d24e0da6fa1f614cf2055f4d7e10206017cd1680;
        const load = 0x231669a6373b644ceefec60da6db3aab0c9dbc21e1bec031f84280478e3fa6c;
        const loadCell = 0xdb525f63a420aa38a856e4c19e200ac8f10976b4de015228977172856e11c4;
        const loadRange = 0x1aeca00e94515d2f6b26e6d60776bba9e2786fa0e615fe600d22a096f711521;
    }

    namespace IBFR {
        const calculateKey = 0x2a5b44d6ee0a59c8c56c2e1fff32c18d3b87c4ec460920be3297c2355cec67f;
        const resolveKey = 0x34ea21e3feb6a55c5631f40cdf6d951f873a548a2eb398ea8f2ad9be519c25;
        const registerElement = 0x1f89a3afca1cd2076a205fe4fc46370aaed0c49f69700691b395a723e96acaf;
        const registerElements = 0x3a0ee961d57284081ae38806062751e01756e9e9e17a6d14e80baa5095b602;
    }

    namespace ZKLANG {
        const deployFunction = 0x1008fe667b9955289844cffb814a4b61b214ab7a1a21f3fc65d2c0f8282925d;
        const deleteFunction = 0x2de4b6e06c340728301857560302e43269482dbe0cd4924767a1652d8941549;

        const __ZKLANG__ARITHMETIC__ADD = 0x1af2cf64315936187c966982e51c7895c3739948ae40fd37e0c616d982bb779;
        const __ZKLANG__ARITHMETIC__SUB = 0x286d1bf0077cee93474ec5fc6e5cafe256dfb90b491eae4c2331af87e2e6172;
        const __ZKLANG__CONDITIONAL__IF = 0xdf1eed657783673942e00c5368c0f086bb31d1fce2ee2227e92272def63b03;
    }

    namespace Init {
        const init = 0x3b6771b04b068edcfb8c265b21ed5c6a5748d427138f776f3f164cc45f75b31;
    }

    namespace DIAMONDCUT {
        const diamondCut = 0xf3d1ef016a3319b5c905f7ed8ae0708b96b732c565c6058e6a4f0291032848;
    }

    namespace ERC20 {
        const totalSupply = 0x80aa9fdbfaf9615e4afc7f5f722e265daca5ccc655360fa5ccacf9c267936d;
        const balanceOf = 0x2e4263afad30923c891518314c3c95dbe830a16874e8abc5777a9a20b54c76e;
        const allowance = 0x1e888a1026b19c8c0b57c72d63ed1737106aa10034105b980ba117bd0c29fe1;
        const transfer = 0x83afd3f4caedc6eebf44246fe54e38c95e3179a5ec9ea81740eca5b482d12e;
        const transferFrom = 0x41b033f4a31df8067c24d1e9b550a2ce75fd4a29e1147af9752174f0e6cb20;
        const approve = 0x219209e083275171774dab1df80982e9df2096516f06319c5c6d71ae0a8480c;
        const increaseAllowance = 0x16cc063b8338363cf388ce7fe1df408bf10f16cd51635d392e21d852fafb683;
        const decreaseAllowance = 0x1aaf3e6107dd1349c81543ff4221a326814f77dadcc5810807b74f1a49ded4e;
    }

    namespace ERC20Metadata {
        const decimals = 0x4c4fb1ab068f6039d5780c68dd0fa2f8742cceb3426d19667778ca7f3518a9;
        const name = 0x361458367e696363fbcc70777d07ebbd2394e89fd0adcaf147faccd1d294d60;
        const symbol = 0x216b05c387bab9ac31918a3e61672f4618601f3c598a2f3f2710f37053e1ea4;
    }

    namespace ERC721 {
        const approve = 0x219209e083275171774dab1df80982e9df2096516f06319c5c6d71ae0a8480c;
        const balanceOf = 0x2e4263afad30923c891518314c3c95dbe830a16874e8abc5777a9a20b54c76e;
        const getApproved = 0xb180e2fe9f14914416216da76338ac0beb980443725c802af615f8431fdb1e;
        const isApprovedForAll = 0x21cdf9aedfed41bc4485ae779fda471feca12075d9127a0fc70ac6b3b3d9c30;
        const ownerOf = 0x2962ba17806af798afa6eaf4aa8c93a9fb60a3e305045b6eea33435086cae9;
        const safeTransferFrom = 0x19d59d013d4aa1a8b1ce4c8299086f070733b453c02d0dc46e735edc04d6444;
        const setApprovalForAll = 0x2d4c8ea4c8fb9f571d1f6f9b7692fff8e5ceaf73b1df98e7da8c1109b39ae9a;
        const transferFrom = 0x41b033f4a31df8067c24d1e9b550a2ce75fd4a29e1147af9752174f0e6cb20;
    }

    namespace ERC721Metadata {
        const name = 0x361458367e696363fbcc70777d07ebbd2394e89fd0adcaf147faccd1d294d60;
        const symbol = 0x216b05c387bab9ac31918a3e61672f4618601f3c598a2f3f2710f37053e1ea4;
        const tokenURI = 0x12a7823b0c6bee58f8c694888f32f862c6584caa8afa0242de046d298ba684d;
    }

    namespace ERC1155 {
        const balanceOf = 0x2e4263afad30923c891518314c3c95dbe830a16874e8abc5777a9a20b54c76e;
        const balanceOfBatch = 0x116d888b0a9ad3998fcf1cdb2711375c69ac1847e806a480e3585c3da18eac3;
        const isApprovedForAll = 0x21cdf9aedfed41bc4485ae779fda471feca12075d9127a0fc70ac6b3b3d9c30;
        const setApprovalForAll = 0x2d4c8ea4c8fb9f571d1f6f9b7692fff8e5ceaf73b1df98e7da8c1109b39ae9a;
        const safeTransferFrom = 0x19d59d013d4aa1a8b1ce4c8299086f070733b453c02d0dc46e735edc04d6444;
        const safeBatchTransferFrom = 0x23cc35d21c405aa7adf1f3afcf558aec0dbe6a45cade725420609aef87e9035;
    }

    namespace ERC1155Metadata {
        const uri = 0x2ee3279dd30231650e0b4a1a3516ab3dc26b6d3dfcb6ef20fb4329cfc1213e1;
    }

    namespace FACET {
        const __constructor__ = 0x3b9a86822e238443322f8092dd01ed69fb0d96d2fad90e9ad9ba03f8e92097b;
        const __destructor__ = 0x2127299f0c39ad6a0f5a7ccb0857ab472c30192b18dd40a88a5af64edd63a74;
        const __get_function_selectors__ = 0x35802e5c93fa05f42af0eb6d6ed857d69b8010fe9d917bfd51f60ffcd2300d6;
        const __supports_interface__ = 0x20f621f78ecca5435389efa53ca29525b75fe9745044ce3b56b4b1e6056d791;
        const __royalty_info = 0xef10f72befea4b2767793ab9151f232f087d5a39ad0d959a7406a84aaaf55a;
    }

    namespace MINTDEPLOY {
        const mint = 0x2f0b3c5710379609eb5495f1ecd348cb28167711b73609fe565a72734550354;
    }

    namespace ERC5114 {
        const ownerOf = 0x2962ba17806af798afa6eaf4aa8c93a9fb60a3e305045b6eea33435086cae9;
    }

    namespace ERC5114Metadata {
        const metadataFormat = 0x1ca90dda6287e49240ebea9347c5f16889c3d322c63f56cb9b41049ff8d8d4c;
        const collectionUri = 0x301d70d6d0526f9060e9cba1cf24f38b94fbbed88395add4575967cdb24ab76;
        const tokenUri = 0x362dec5b8b67ab667ad08e83a2c3ba1db7fdb4ab8dc3a33c057c4fddec8d3de;
    }

    namespace ERC2981 {
        const royaltyInfo = 0xfd0f1dab5939609a69ab50ab7865a11834a0c52e41ca72e4e943447b9d3bf0;
    }

    namespace ERC4906 {
        const updateTokenURI = 0x2ce2072fc0e89a2053fac74913af88590b52e043d8a71a775737487a427e3d0;
        const updateTokenBatchURI = 0x3c6f820fdee2e32345dc4f820b22fcdf1e015a504eabc9d9478aa24ce57e480;
    }

    namespace ERC5007 {
        const startTime = 0x10b044cec2cbe9626acf846613faf0242f9ee639539af4877c180efd6ae5ea7;
        const endTime = 0xed51e84d6fefb29eead3c69fb1bfe5372d012fe89adcbd9243678bec90b4d1;
        const setTimePeriod = 0x215fd33d2093f5576533be617d22a77ab03de59b44b45ba51d815d9a9a4eff2;
        const checkTimePeriod = 0x56ba2240ba596b97c6ddee7d72a7d2d4e9789096f17c8f1e47cf98ef54918e;
    }

    namespace ERC5185 {
        const updateMetadata = 0xd1df127d90a37687d0a986a667f4f88eebc4437582fa7bff7d6955ab689037;
    }

    namespace ERC4907 {
        const setUser = 0x390ad5baaccaa89f2506f2a4d742c7f3e1faca465bb358810156d68b69786c;
        const userOf = 0x3bd45318b11387257d49743e18e91d0bacdddd87fddd9528e1432b9a93fd7ab;
        const userExpires = 0x3c0a79768a8c497262c18c4602a67ff7059be721041195f8dfa0ba74028894b;
    }

    namespace ERC4675 {
        const setParentNFT = 0x1fa8bc0752d6e906425fe2e500badd45d6a671a1c35f2f1a60f30b06a809395;
        const totalSupply = 0x80aa9fdbfaf9615e4afc7f5f722e265daca5ccc655360fa5ccacf9c267936d;
        const balanceOf = 0x2e4263afad30923c891518314c3c95dbe830a16874e8abc5777a9a20b54c76e;
        const approve = 0x219209e083275171774dab1df80982e9df2096516f06319c5c6d71ae0a8480c;
        const allowance = 0x1e888a1026b19c8c0b57c72d63ed1737106aa10034105b980ba117bd0c29fe1;
        const isRegistered = 0xe67252e1eb7d86710def42b0b608424428dffb6810c123a41f9b22d4b564ec;
        const transfer = 0x83afd3f4caedc6eebf44246fe54e38c95e3179a5ec9ea81740eca5b482d12e;
        const transferFrom = 0x41b033f4a31df8067c24d1e9b550a2ce75fd4a29e1147af9752174f0e6cb20;
    }

    namespace UNIVERSAL_MINT {
        const mint = 0x2f0b3c5710379609eb5495f1ecd348cb28167711b73609fe565a72734550354;
        const mintBatch = 0x348b9a6e049cc3f9f66737435ed36813556cc5be1cf9d5c64f429c32a17d88a;
    }
}
