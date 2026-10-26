`timescale 1ns/1ps
// External exact big-integer fixtures generated independently,
// including numerator = (2^127-1)^3, divisor=(2^127-1)^2+1.
module tb_wide_division_golden;
    import pcal_exact_division_pkg::*;
    logic [383:0] quotient, remainder;
    integer cases=0;

    task automatic check_vector(
        input integer id,
        input logic [383:0] numerator,
        input logic [383:0] denominator,
        input logic [383:0] expected_quotient,
        input logic [383:0] expected_remainder
    );
        begin
            quotient=exact_quotient_384(numerator,denominator);
            remainder=exact_remainder_384(numerator,denominator);
            if (denominator==384'b0 || quotient!==expected_quotient ||
                remainder!==expected_remainder)
                $fatal(1,"WIDE_DIVISION_GOLDEN_MISMATCH id=%0d q=%h r=%h",
                       id,quotient,remainder);
            if(quotient*denominator+remainder!==numerator ||
               remainder>=denominator)
                $fatal(1,"WIDE_DIVISION_INVARIANT id=%0d",id);
            cases=cases+1;
        end
    endtask

    initial begin
        check_vector(1,384'h1fffffffffffffffffffffffffffffff400000000000000000000000000000017fffffffffffffffffffffffffffffff,384'h3fffffffffffffffffffffffffffffff00000000000000000000000000000002,384'h7ffffffffffffffffffffffffffffffe,384'h3ffffffffffffffffffffffffffffffe80000000000000000000000000000003);
        check_vector(2,384'h3fffffffffffffffffffffffffffffff00000000000000000000000000000001,384'h80000000000000000000000000000000,384'h7ffffffffffffffffffffffffffffffe,384'h1);
        check_vector(3,384'h7fffffffffffffffffffffffffffffff,384'h7ffffffffffffffffffffffffffffffe,384'h1,384'h1);
        check_vector(4,384'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,384'h1,384'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,384'h0);
        check_vector(5,384'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,384'h3fffffffffffffffffffffffffffffff00000000000000000000000000000002,384'h400000000000000000000000000000010,384'h7ffffffffffffffffffffffffffffffdf);
        check_vector(6,384'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,384'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,384'h1,384'h0);
        check_vector(7,384'h1fffffffffffffffffffffffffffffff400000000000000000000000000000017ffffffffffffffffffffffffffffffe,384'h3fffffffffffffffffffffffffffffff00000000000000000000000000000002,384'h7ffffffffffffffffffffffffffffffe,384'h3ffffffffffffffffffffffffffffffe80000000000000000000000000000002);
        check_vector(8,384'h1fffffffffffffffffffffffffffffff4000000000000000000000000000000100000000000000000000000000000000,384'h3fffffffffffffffffffffffffffffff00000000000000000000000000000001,384'h7ffffffffffffffffffffffffffffffe,384'h3ffffffffffffffffffffffffffffffe80000000000000000000000000000002);
        check_vector(9,384'h0,384'h7b,384'h0,384'h0);
        check_vector(10,384'h1,384'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,384'h0,384'h1);
        check_vector(11,384'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,384'hfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe,384'h1,384'h1);
        check_vector(12,384'h3fffffffffffffffffffffffffffffff80000000000000000000000000000001,384'h7ffffffffffffffffffffffffffffffe,384'h80000000000000000000000000000001,384'h3);
        check_vector(13,384'hcc1fe3a90706ccc82373b0a03dfd52ef41ffd4c86874edee2fae5e08c86804fa06e9501522f3b40779299d45459ab93,384'h22aca9443ac372bd35c8987db6b7f59a78f950c5121a0d7dd336407377655d37,384'h5e30aefe1b60cd20c136d71a52c40861,384'h1c3d6ebd49dd1603a8df57b0641c8e68627b43d880f44843072c084befeba1bc);
        check_vector(14,384'h106fad0320fb49e8301d5c635145971c2f776fac8afa795ae445126701047c18d516035e69fab21cffaa0460f120b441,384'he495011fde774ae5f6e548efd3f55e8083ad8e1e16f359014848dfab0565b9974d4ba7455947d421966c99d2c0f43ee,384'h1,384'h2265cf12313d539d0af07d454064134273c96caa98b43cacfc0846c50ae207f604148ea146634dae6433ac3c5117053);
        check_vector(15,384'hacd15fbfb640844b83fa221c7aab14595bba53cce57e716324b7a2ee04d0a29704150c7e52f9e380eda90dc96dc192a,384'hb62e682bce5de01706c0e819e3390d6,384'hf2d7b449542c94c425d585c636db7dcedb72912a7e00a2a6c0c6cb9bf0197083,384'h661e0a0e7f929f11fa740ee4e355ba8);
        check_vector(16,384'h1a6f856a8c9523e0cbd8b2cc0bcaefb10b912d3f2bd67412bdca83c9f628d676378243d33f683b94de4796746f6c6655,384'h51eb8d31b4b12239cc47cd3ebd5963397f882784b46fb5f86caa52bf4034a43,384'h529c78c88a2496a440ce52b72f06bc4f5,384'h4b29149d707314c02eec0acac3aae01e7b9674d9c415ea1b0e076bc896a0836);
        check_vector(17,384'h13c59650bfbc58bcd56942d290f45e5dfef1eca89c223c4e6d9db621a6bccd00ee5d17c2c03606300b2b05cd67e867c2,384'h828ca9ce47ee238ce0754d80ded09129dfda67caea2e411a305b2039d3f63d0911552e51cc2b69797f043ddfc054e,384'h26c,384'h2cb9cc6590cdb426f81574f3a4c64e84f9d72a52fbbf3b6cbeb00e5e74743cefd72ffde8e73f8e731216fc98b8eda);
        check_vector(18,384'h170aba57f526a2d896ab876021b34949a31c5cb28f989bcaf5c728b38f1619ccced44c4f27bdba0cfa89c2e4ec09296e,384'h1395972a244cf2de6564a0e7824c995,384'h12d323963098f689a40f243167ba90962ae32f21ce70430ad083129e7659b9de64,384'ha0e49c623698a61f89cbb59d2e353a);
        check_vector(19,384'h10ab048d6e5c3e347c608f66c4be3c7720cce50c3fc42e86aaf412d55bf628d5b2e510dfa4935328497ea9eb41d5f75c,384'h2428847a81dd61c5b6ebc7c49383f2037e0630f96e7fc185079be18a523dfa9d,384'h76026b6a26325acd2fdf15771f3575ff,384'h9d4f84ea02073e3053dedee4739f1f163cdee61ed7538d1936ae1641d0e93f9);
        check_vector(20,384'h37ade0a6b7ca6d07476d2498a2203e24e44a7189418d082ca7c2b7b42dea623ce7e94760ed60d84e8508468d1905d87,384'h1909e2b2bd6aee5694a8dbfe8f7e106da3e828d6a62777786e1ff22fe97409677becf92a9e6a416a5aafb379113a96f2,384'h0,384'h37ade0a6b7ca6d07476d2498a2203e24e44a7189418d082ca7c2b7b42dea623ce7e94760ed60d84e8508468d1905d87);
        check_vector(21,384'hef0bf9975da98acb60f8eba0cadab8beb9f71ee75ef9dbe09f5689cc95d7db5819c3880a48c65202c6cf619e5e027ef,384'hcf8db3b0ca4811855b0100f42972413,384'h126d82497745b53115b05d015fc263b4bd7500d904ce40267c42e1d4fdc9af5df,384'h128f53fec88c5888f24234b37438c62);
        check_vector(22,384'h93aabfd93d80fc8db711b02b39e7f772a33ff16afc2f23ac7959c3fc698db81a7d01809c34015fcaf204532b03f629b,384'h22be1103bba205ac7fdcaebb5c16dd166df1455b566283e686a5cd0e67bdc233,384'h44015dca6d4dfb6ed23ee7d4b643ce08,384'h21e27cba53b795692f487b5a92515e9b2cfaec7007c44d8b24af5f4eaab34703);
        check_vector(23,384'h1eec3cef62024824b8c0aa45008c0ba542f6f183b3aa69f6df0587a9cb1b2b88bd50e3a15ada1c185ec2fc6f9da6598a,384'h694c77463a2370a2994a2e4f50b2414daae2c7c9b26474c4005c12c49bcbda56a97af14b833ad5eeb5a2896cb349cda,384'h4,384'h4991f1dd3796bfc126e1eb12c5f7b51d83e3f9147114cc5deee82f8a42834f312f2274e7a0b669cb15a5a1470d3e622);
        check_vector(24,384'h638e66f4d6dbdc00f01346d75941c10b161a23ce516e0f2231d897c5adf19d63b49d61b15beb37406b3eeb4477798b5,384'h4c54e1f2de3edfc4aa33d68ad9cd1c47,384'h14de404db335e5fa08c7ba2632be4718866b0ce0487aa7f053b7a1caf97dd131,384'h4a41a4e8f22c26fa3a99b1a24574381e);
        check_vector(25,384'ha0621f36b522c9cb5cd9904dfc6bcbd8b5473f041ce732e9e61bbd0a59b926096d09417722958108df498458cabec22,384'h3af9587f9194e1cde63d50ac43f16b71266b9169c109a68d8e376ae3eac234fe,384'h2b835044854463719b9f9e95904d33fc,384'h2a4f6ee7a0886b5d63867973cfa75dbed0b3a9aaa74c5a39f7018216f48b281a);
        check_vector(26,384'h1e607a7aa9e690b8254203d911d239aa35e8ef5286287caaf5478a03a94fc12bd91e718548c8c5ece47b41219f3e5fcf,384'hf5722d4ec0b0cfeaf5046f5e8a0cbfa6db473551272e6606a18cdbecbc3a02689ecedcc049cfa92bc5dfc10d647fb00,384'h1,384'hf0957a5bddb83b975f1bce329316dafc8347bfd73b5964a8b2ebc44dd8c21054f3183b9442bcb5a281d4510c8f664cf);
        check_vector(27,384'hca6acee567d26148e205df55aef1ed8534c2927288999667451c50beb0f1234bd33aa1c7c9af908973272db11d83fbd,384'h4d99ba7307a97319884b53ac026ee4a,384'h29bc38a971ddf2be8c1dd4bc44f66220a3d50c197adba9f3f429f96a36db77510,384'h40b0da30c6386609ae440f56b9b891d);
        check_vector(28,384'h124bf2b634df68b02f43c9cd460c383fd3031f36c81fa562818d7f26320d318987f11d81d0092d645ae02aea31bd17e3,384'h1c0e9a239c6a1a30431a104d7499f101d4dab152c26fcd7261c6e89f29b62716,384'ha6f19b41635b5dc35d971f20d461a7f4,384'h1115a6681f1debd5eddc7cb99c6180f3c540dd7a4d4e153c23366bdd954a7ceb);
        check_vector(29,384'h719083aa3ea148c3d52f7126d3a91efc40ea6a3eaddbc9e95245ea6f0ea0b0c22679a8f1b43df0001c5dce238f6b455,384'h12dec86c43364323a78a2f71c3eec1d66492b0dfc2468b4d86284f4ba8334eba786afd7cd2b5d0625a0cf1f77aad563,384'h6,384'h57d120ab5bb5ede7f2547c3c1093f5e57a4500203486182d540ea91d6cd86353f7b804c3fb0db200102256af5b403);
        check_vector(30,384'h13b303838b6925a8f5b675b06d5977dbbb9ae33326b83b1a9b2b320a493dcad9c49778625fdec9dc3e418e9e24c12100,384'h74a99b23c297135d5dfcadc9e65e9606,384'h2b3a34ba627c957fdd3e54fc0266384b6e7c65539f0d663cffe99d8db3a9979f,384'h35d422ef4c07fbb183e200b1098e6946);
        check_vector(31,384'h3c8c1720f33d8049972181846027603e7cdd77d1220bcd631bbd734d564dcedf731649975ace9f8eaba9f8b3c36a9e7,384'h36240098d0b212d839f5085fc10e01dd35d278379713dc92f4f9d5a56e03ac60,384'h11e4b090d2cc5c7598892125860259bf,384'h1297b723e23f017d0d026d648a8fe18be757cc254f2b0719670ca3bd47cbae47);
        check_vector(32,384'h19acb77e4388a7a0775d379eb1b55873826898dd97c21dd27742a37ba48bed30e762e5bf4cdc7b54e16cb3f5933bdb19,384'he6306ebb0aa70a6f15711646bdda87d2387b3aa10b52248e13e94f017283ff742b7dd058ff948ba2af4f6467d8f9002,384'h1,384'hb49b09292de36f98606263a45d7aff65ee0e533870cfb8996040e8b8d63ad39a4ab08b9bce3329ab677bdaf15ac4b17);
        check_vector(33,384'h1b5db5a95ea9507c2001227742442b1c0603d28d897c7a0e16fc7bba14fbe7c3f7d60cab0152f9f05f99a1e515ab8080,384'h616c3c65c11880482c6766cc4d83cf83,384'h47e90e2ffa79fa39aa1ea10e6119bed95142cbbaab28747828b2adbb744afbdd,384'h1bb82553ccf68086eac355b3968deb69);
        check_vector(34,384'hd4475b823b6ce98305ec6084d7f3a0af9a628e88ea12d8ac89f71b878a5f88b499e60a83b4921ccbbf186efe6c2a62f,384'h3394b31f673d6fba9b88d17c1b5671e482bf054f7adcf7f8ce2de59bde281904,384'h41d8e82417a43bd7e42db7821d1abef2,384'h1c5703d933c0170f5b7f21da2215e7ab4f5122e7d30835425a331fc623e20867);
        check_vector(35,384'ha4a530882cd5df492ea7a31f6211134af5973b2c96ed44636f4b0aeafef8b9bb570e5f39926eee8022691a920cc9818,384'h7079c59434a65a2a7bd199ad9165234520fb104356a71c3931a9ba5dd5c5375082c126d22a71aeb8ae719ec988cee9,384'h17,384'h2f624832126bdac1caa5635e10fb097962e53cbca5d0bd137e70f041bad3a379b18b76b756b8356a7a5c6505820129);
        check_vector(36,384'h1b00c6b0aa607a90bc78a6ecdcfa7ca0b69fc37ecfcd4a42bf559c0226be4ce63db29da51e9f9d44f549c641410ee245,384'h23a9170851f3c9f5ed5fc7f97eb816bf,384'hc1d9812fd692ca0c6ceadea6e82209777a31d04dc09c3f866a3b9088543af696,384'hcc2f004369d51b764937a84810045b);
        if(cases!=36) $fatal(1,"WIDE_DIVISION_VECTOR_COUNT");
        $display("STAGE1_384BIT_LONG_DIVISION_GOLDEN_PASS cases=%0d",cases);
        $finish;
    end
endmodule
