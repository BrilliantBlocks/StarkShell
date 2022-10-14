const ALL_ONES = 2 ** 251 - 1;
const NULL = 0;
const IERC165_ID = 0x01ffc9a7;
const IERC20_ID = 0x01ffc9a7;
const IERC721_ID = 0x80ac58cd;
const IERC721_METADATA_ID = 0x5b5e139f;
const IERC1155_ID = 0x01ffc9a7;
const IERC5114_ID = 0x01ffc9a7;
const IERC2981_ID = 0x2a55205a;
const IERC4906_ID = 0x49064906;
const IERC5007_ID = 0x7a0cdf92;
const IERC4907_ID = 0xad092b5c;
const IERC4675_ID = 0x83f5d35f;
const IERC5185_ID = 0x00000001; // TODO
const IERC721_RECEIVER_ID = 0x150b7a02;
const IACCOUNT_ID = 0xf10dbd44;
const IDIAMONDLOUPE_ID = 0x123;  // TODO
const IDIAMONDCUT_ID = 0x123;  // TODO
const FEE_DENOMINATOR = 10000;


namespace FUNCTION_SELECTORS {
    namespace DIAMONDCUT {
        const diamondCut = 0xf3d1ef016a3319b5c905f7ed8ae0708b96b732c565c6058e6a4f0291032848;
        const setAlias = 0xf6c02362df0f19e3d15dda5d9a650cc9f369907e8c5d36f99c0fdbcb84e6d0;
        const setFunctionFee = 0x230f7ba57083bd3af29b5549569aeb558350a7a4519a9b5f755eda20d1c5d80;
    }

    namespace ERC20 {
        const name = 0x361458367e696363fbcc70777d07ebbd2394e89fd0adcaf147faccd1d294d60;
        const symbol = 0x216b05c387bab9ac31918a3e61672f4618601f3c598a2f3f2710f37053e1ea4;
        const totalSupply = 0x80aa9fdbfaf9615e4afc7f5f722e265daca5ccc655360fa5ccacf9c267936d;
        const decimals = 0x4c4fb1ab068f6039d5780c68dd0fa2f8742cceb3426d19667778ca7f3518a9;
        const balanceOf = 0x2e4263afad30923c891518314c3c95dbe830a16874e8abc5777a9a20b54c76e;
        const allowance = 0x1e888a1026b19c8c0b57c72d63ed1737106aa10034105b980ba117bd0c29fe1;
        const transfer = 0x83afd3f4caedc6eebf44246fe54e38c95e3179a5ec9ea81740eca5b482d12e;
        const transferFrom = 0x41b033f4a31df8067c24d1e9b550a2ce75fd4a29e1147af9752174f0e6cb20;
        const approve = 0x219209e083275171774dab1df80982e9df2096516f06319c5c6d71ae0a8480c;
        const increaseAllowance = 0x16cc063b8338363cf388ce7fe1df408bf10f16cd51635d392e21d852fafb683;
        const decreaseAllowance = 0x1aaf3e6107dd1349c81543ff4221a326814f77dadcc5810807b74f1a49ded4e;
    }

    namespace MINT_BURN_ERC20 {
        const mint = 0x2f0b3c5710379609eb5495f1ecd348cb28167711b73609fe565a72734550354;
        const burn = 0x3e8cfd4725c1e28fa4a6e3e468b4fcf75367166b850ac5f04e33ec843e82c1;
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

    namespace ERC1155 {
        const balanceOf = 0x2e4263afad30923c891518314c3c95dbe830a16874e8abc5777a9a20b54c76e;
        const balanceOfBatch = 0x116d888b0a9ad3998fcf1cdb2711375c69ac1847e806a480e3585c3da18eac3;
        const isApprovedForAll = 0x21cdf9aedfed41bc4485ae779fda471feca12075d9127a0fc70ac6b3b3d9c30;
        const setApprovalForAll = 0x2d4c8ea4c8fb9f571d1f6f9b7692fff8e5ceaf73b1df98e7da8c1109b39ae9a;
        const safeTransferFrom = 0x19d59d013d4aa1a8b1ce4c8299086f070733b453c02d0dc46e735edc04d6444;
        const safeBatchTransferFrom = 0x23cc35d21c405aa7adf1f3afcf558aec0dbe6a45cade725420609aef87e9035;
    }

    namespace MINT_BURN_ERC1155 {
        const mint = 0x2f0b3c5710379609eb5495f1ecd348cb28167711b73609fe565a72734550354;
        const mintBatch = 0x348b9a6e049cc3f9f66737435ed36813556cc5be1cf9d5c64f429c32a17d88a;
        const burn = 0x3e8cfd4725c1e28fa4a6e3e468b4fcf75367166b850ac5f04e33ec843e82c1;
        const burnBatch = 0x2e0d76db1c0a81450ed8b20b81e606bc417da81fd9ca869327abd60ba226704;
    }

    namespace FACET {
        const __get_function_selectors__ = 0x35802e5c93fa05f42af0eb6d6ed857d69b8010fe9d917bfd51f60ffcd2300d6;
        const __init_facet__ = 0x101d2ba76f87b0ae8750c488387d702c0b092c6c6e91348ccf5d6dc2d734818;
        const __supports_interface__ = 0x20f621f78ecca5435389efa53ca29525b75fe9745044ce3b56b4b1e6056d791;
    }

    namespace MINTDEPLOY {
        const mint = 0x2f0b3c5710379609eb5495f1ecd348cb28167711b73609fe565a72734550354;
    }

    namespace ERC5114 {
        const ownerOf = 0x2962ba17806af798afa6eaf4aa8c93a9fb60a3e305045b6eea33435086cae9;
        const metadataFormat = 0x1ca90dda6287e49240ebea9347c5f16889c3d322c63f56cb9b41049ff8d8d4c;
    }

    namespace MINT_ERC5114 {
        const mint = 0x2f0b3c5710379609eb5495f1ecd348cb28167711b73609fe565a72734550354;
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

    namespace LAZYMINT {
        const mint = 0x2f0b3c5710379609eb5495f1ecd348cb28167711b73609fe565a72734550354;
        const addToWhitelist = 0x1bd2f341b15c21adf730026e0c6072773a188c5098349929b39d7ea612f79f8;
        const changeWhitelistSetting = 0x35020ce616815178e52c9588723c3dea479b11797a6836686cc6bfb54c23bfd;
        const getWhitelistSetting = 0x8988d153b42bd8ad378926f7dfc81d2909200c7683953a04cc44718b2ca7dc;
    }

    namespace BATCHMINT {
        const mintBatchConsecutive = 0x1c7d5f1f8b2fe560ddb59a71a1b6c4633502700a50a01a7adbcd5cef0b39a97;
    }
}
