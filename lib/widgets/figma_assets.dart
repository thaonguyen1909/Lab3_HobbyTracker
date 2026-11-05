import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/hobby_theme.dart';

const figmaAssets = <String, Map<String, String>>{
  'art': {
    'imgIconLeaf': 'assets/figma/d2e3f943-cf27-4011-973c-7d05a5d5bbe6.svg',
    'imgThemeMotifArt': 'assets/figma/262fa1a1-54c1-41d3-8fce-5f5df7ea53b4.svg',
    'imgIconBack': 'assets/figma/b96a9e3a-bc90-4b73-9b3c-e12123931784.svg',
    'imgIconChevron': 'assets/figma/d399c94c-2d54-4ecd-ad3f-a12e71a689ef.svg',
    'imgActivityDot': 'assets/figma/51e1e6f4-a6c7-4dc5-927b-495b3a528d41.svg',
    'imgIconCamera': 'assets/figma/90d665aa-02ea-438d-a09e-f0020b9403dc.svg',
    'imgIconArchive': 'assets/figma/233b4df2-5f7d-4cc5-b089-47ef9d72f05c.svg',
    'imgIconHome': 'assets/figma/a4f1b53d-dc18-4b8f-a1ed-053ad6935eba.svg',
    'imgIconLeaf1': 'assets/figma/4ed4b25a-fc98-459c-82fa-21b0d7c00852.svg',
    'imgIconHeart': 'assets/figma/dfa71894-d2f1-4f5b-bfee-e00489509b75.svg',
    'imgIconSettings': 'assets/figma/f2243eed-b9d7-4d1a-befe-ad01e5c0f17f.svg',
  },
  'forgot': {
    'imgIconLeaf': 'assets/figma/5025afca-58c7-48c7-ac24-3a8fbf7dc6ec.svg',
    'imgIconBack': 'assets/figma/92d1c61c-63be-41f5-8ade-43c6d9f705fb.svg',
    'imgThemeMotifLight':
        'assets/figma/bbc3d1af-7464-42f4-aa1c-2304fc3d3c2e.svg',
  },
  'rainy': {
    'imgIconLeaf': 'assets/figma/61ec0cfc-f180-4592-9a9e-989149077d72.svg',
    'imgThemeMotifRainyDay':
        'assets/figma/6df4ecbf-78b6-4451-9190-d71908d8f8bd.svg',
    'imgIconBack': 'assets/figma/b1eded4d-39a6-485b-854e-50916d1d4882.svg',
    'imgIconChevron': 'assets/figma/e424719b-8d61-4599-8c15-b79d0a39fada.svg',
    'imgActivityDot': 'assets/figma/ac842d63-f5f0-4b37-a88b-988d21423087.svg',
    'imgIconCamera': 'assets/figma/0d854859-d72a-45f4-a422-7f2d4ce3271a.svg',
    'imgIconArchive': 'assets/figma/2ecdf480-6821-41ec-8122-a39e5f62d395.svg',
    'imgIconHome': 'assets/figma/11ddafd1-798a-4b21-952d-4326a837d7ee.svg',
    'imgIconLeaf1': 'assets/figma/393652ab-a2c6-41aa-a84f-7e0cc7ff88d1.svg',
    'imgIconHeart': 'assets/figma/cd03465c-aec0-46b8-9f66-5f3e3f6e324e.svg',
    'imgIconSettings': 'assets/figma/02f840ac-0d83-488c-9390-ffbdac4205b0.svg',
  },
  'feed': {
    'imgIconHome': 'assets/figma/3077cb36-80ce-489f-bf60-b569f1b9fcb8.svg',
    'imgIconLeaf': 'assets/figma/5eafc0d5-c973-46f5-8a05-7ec3b163d804.svg',
    'imgIconHeart': 'assets/figma/f848e237-bf39-4819-9c3b-e1c5e57a19e2.svg',
    'imgIconSettings': 'assets/figma/9f7a1696-2bb7-4b34-9543-c52b101fdc21.svg',
    'imgIconLeaf1': 'assets/figma/3a117e91-6d72-47af-a3a0-f8c3aebfcbeb.svg',
    'imgIconHeart1': 'assets/figma/bd0aa28e-cc17-4939-b8ec-a21e3d584a4a.svg',
    'imgIconChat': 'assets/figma/877be662-0096-4ddc-b0f5-7b598f6717d1.svg',
  },
  'notifications': {
    'imgIconHome': 'assets/figma/49f853f4-9618-40ba-89b6-8af3a8f59e88.svg',
    'imgIconLeaf': 'assets/figma/22607ce1-4045-4db2-93e6-bf87f1ffc9bc.svg',
    'imgIconHeart': 'assets/figma/1a7bb6dd-5ab5-434a-bb68-70ee002256c3.svg',
    'imgIconSettings': 'assets/figma/15d018a1-7910-4bea-bf6b-51290436c28b.svg',
    'imgIconCheck': 'assets/figma/0db831c0-0987-4ca7-a86d-60233e37abd3.svg',
    'imgIconLeaf1': 'assets/figma/bb764c36-130d-4025-be77-1727acf43fa9.svg',
    'imgIconBack': 'assets/figma/a82c9c17-7d61-4ce6-b79d-f0befbd14b58.svg',
  },
  'hyperprefs': {
    'imgIconHome': 'assets/figma/0732fe69-5023-44b2-87cc-49c312c8d971.svg',
    'imgIconLeaf': 'assets/figma/4f37f5de-ca96-416f-9c5a-9458a322d097.svg',
    'imgIconHeart': 'assets/figma/a26e2535-b4bc-4a23-97a7-38f31b1216bf.svg',
    'imgIconSettings': 'assets/figma/3012661f-7fe8-411d-88b4-7bdb5cfea016.svg',
    'imgIconCheck': 'assets/figma/a53b1bc5-2ae9-4183-8fdd-eb1a43a8ed85.svg',
    'imgIconLeaf1': 'assets/figma/ca6fae2e-0ab3-4ef1-8560-15245b0e8bd8.svg',
    'imgIconBack': 'assets/figma/8653205e-9b0e-4496-bc99-2a76d32e1b76.svg',
  },
  'inbox': {
    'imgIconHome': 'assets/figma/e976c1bc-1e24-473f-8878-3bb88b076d92.svg',
    'imgIconLeaf': 'assets/figma/29705f58-d594-4240-b298-d833bc487c07.svg',
    'imgIconHeart': 'assets/figma/a7bfe988-0b2c-4ea6-afba-03d77d5e3bb1.svg',
    'imgIconSettings': 'assets/figma/d5f21089-eb73-41a2-98a1-811a1bdaa021.svg',
    'imgIconLeaf1': 'assets/figma/1b90b591-2a6b-4e2e-86d3-3420c3bb70c8.svg',
    'imgIconChevron': 'assets/figma/b3bff281-149a-4366-9db5-8026c0c23874.svg',
  },
  'settings': {
    'imgIconHome': 'assets/figma/214824fa-6960-4d02-82d1-62ffcc485344.svg',
    'imgIconLeaf': 'assets/figma/e0b5bc31-3d38-46ef-8e61-ce4cc25d4890.svg',
    'imgIconHeart': 'assets/figma/e600acba-b7bb-4251-a560-97cf2af5d26a.svg',
    'imgIconSettings': 'assets/figma/4093c421-645d-4f03-afbf-e18334842c32.svg',
    'imgIconLeaf1': 'assets/figma/896e3ece-5688-4f56-be50-3837a986ebba.svg',
    'imgIconEdit': 'assets/figma/bbdcc82a-113b-4f9e-979f-22f349bedbfc.svg',
    'imgIconUser': 'assets/figma/a902e13e-2ade-4a11-b939-40574d4308b4.svg',
    'imgIconChevron': 'assets/figma/828e1d6a-d09c-41b8-8eaf-6ce245af7812.svg',
    'imgIconHeadphones':
        'assets/figma/e86da15f-4fa7-48bd-aca8-6484e125d59a.svg',
    'imgIconBell': 'assets/figma/e490d86d-4c9b-48bc-8800-5e84f7905d06.svg',
    'imgIconClock': 'assets/figma/ae52bc43-2f2e-4ac1-86ff-e0fd7e451abc.svg',
    'imgIconPalette': 'assets/figma/2dcae6ce-d6a5-45fe-ba71-86babcdb09f1.svg',
    'imgIconLock': 'assets/figma/e8a1c79a-324c-4df4-a51e-e4674f1a8887.svg',
  },
  'register': {
    'imgIconLeaf': 'assets/figma/7bb38617-666b-434b-ad25-0e0a0f7d9697.svg',
    'imgIconBack': 'assets/figma/9b5bcd3c-ff06-41cb-814f-8d67d212b440.svg',
    'imgThemeMotifLight':
        'assets/figma/8eace986-d1ab-41ce-9a3b-87cf62ab47b2.svg',
    'imgIconEye': 'assets/figma/70d32d82-dde2-4981-b2b3-e64f67c49399.svg',
  },
  'cyber': {
    'imgIconLeaf': 'assets/figma/09e88353-1458-4193-bc29-e54e3b0c02d9.svg',
    'imgThemeMotifCyber':
        'assets/figma/bb3a61ad-ca61-487b-8b80-772fd4425df2.svg',
    'imgIconBack': 'assets/figma/54b35cf9-89ce-4057-861a-23f1793089c8.svg',
    'imgIconChevron': 'assets/figma/42f0646f-93f0-4925-a596-322c96e74737.svg',
    'imgActivityDot': 'assets/figma/65676f68-da83-44cc-8230-da79fb38e29b.svg',
    'imgIconCamera': 'assets/figma/bd9de9ea-726e-489a-adf0-543f427f04f8.svg',
    'imgIconArchive': 'assets/figma/d0bb2393-35b3-415b-9e74-f2897d1d7933.svg',
    'imgIconHome': 'assets/figma/93562f79-411a-4cfa-a7b2-59cf3ef38e03.svg',
    'imgIconLeaf1': 'assets/figma/ccf3ee4f-db66-4a4b-8493-0be647d4ae92.svg',
    'imgIconHeart': 'assets/figma/0fb06525-e32a-428a-b3b2-a0811b968b42.svg',
    'imgIconSettings': 'assets/figma/e3daf85a-b19e-4f47-96e5-64f177c4b3eb.svg',
  },
  'post': {
    'imgIconHome': 'assets/figma/3e7b4df2-203b-45e2-9a5e-10249cfccb4d.svg',
    'imgIconLeaf': 'assets/figma/ef0a220e-37c1-4bb9-87bf-dc06b235b008.svg',
    'imgIconHeart': 'assets/figma/1be5c8b7-4b77-4648-a809-77d17a4e706e.svg',
    'imgIconSettings': 'assets/figma/eb5e7258-817c-4de3-9d55-a5d91bc4b7db.svg',
    'imgIconLeaf1': 'assets/figma/23c0a01c-2c65-49a4-bafb-be996cfa3c95.svg',
    'imgIconHeart1': 'assets/figma/a37f8353-1357-4b4a-9e44-cc5260b13a66.svg',
    'imgIconChat': 'assets/figma/2906e697-036e-4f84-98e3-e5b1a71f99f6.svg',
    'imgIconClose': 'assets/figma/a97007ab-09ca-4f68-8963-6ecc6e68793e.svg',
  },
  'light': {
    'imgIconHome': 'assets/figma/83ea1347-0cd9-41d1-90f5-7e1983494e31.svg',
    'imgIconLeaf': 'assets/figma/85682b47-54fc-45ec-861d-bf10c828805c.svg',
    'imgIconHeart': 'assets/figma/584f9466-48d8-42ea-822d-4bfce2175f83.svg',
    'imgIconSettings': 'assets/figma/567b78e8-33e8-490b-b525-7f7b3990d0af.svg',
    'imgIconLeaf1': 'assets/figma/4fc905cb-3701-44d4-b48c-b5a4d47bb980.svg',
    'imgThemeMotifLight':
        'assets/figma/5658d426-2da7-46e2-84c1-c32e3360745e.svg',
    'imgIconBack': 'assets/figma/3c9ba067-b7e8-4660-b4a4-3d72e17d84d8.svg',
    'imgIconChevron': 'assets/figma/77923c86-6355-4fd7-8e00-8182ff8ed9a0.svg',
    'imgActivityDot': 'assets/figma/11e31dc6-af41-469b-97f3-0eb5044d9581.svg',
    'imgIconCamera': 'assets/figma/80585263-a741-4518-abbd-9c3da8fc114c.svg',
    'imgIconArchive': 'assets/figma/557b2f78-6e7e-4173-8cda-a88e078fa579.svg',
  },
  'home': {
    'imgIconHome': 'assets/figma/be658b40-9483-41a2-a0c2-db2cd55b2a24.svg',
    'imgIconLeaf': 'assets/figma/3c67e15a-a22c-4890-bc2c-4faf78a16136.svg',
    'imgIconHeart': 'assets/figma/4d84a512-4246-483c-adf8-9e34f4a120d4.svg',
    'imgIconSettings': 'assets/figma/25f47a8f-d2ae-48ae-92c6-e8b004d086e4.svg',
    'imgIconLeaf1': 'assets/figma/b3c61ee1-d374-4a32-ae88-aa001de7016d.svg',
    'imgThemeMotifLight':
        'assets/figma/100d3a9a-1100-47c8-9793-4ebb1a461108.svg',
    'imgIconBack': 'assets/figma/a80aade2-e3f7-4b3a-9dc0-1fe2db45caef.svg',
    'imgIconChevron': 'assets/figma/72a884cb-c035-4edc-af98-18f64f99771c.svg',
    'imgActivityDot': 'assets/figma/496eccb7-104a-4ec3-ba27-25ff3474abda.svg',
    'imgIconCamera': 'assets/figma/6d94cfd4-7179-44a9-93e8-7482dab671cc.svg',
    'imgIconArchive': 'assets/figma/4d12941e-f272-4746-a1ff-08c5d59f8033.svg',
  },
  'detail': {
    'imgIconHome': 'assets/figma/bb0d7625-9dba-4d84-9cf2-e79dad93b6c3.svg',
    'imgIconLeaf': 'assets/figma/134b91ff-70ec-4c65-9aa8-4fcd635ad3ac.svg',
    'imgIconHeart': 'assets/figma/6a5f28b9-4f69-41c8-b5c6-f910a2216d07.svg',
    'imgIconSettings': 'assets/figma/f96aa6ff-4860-447f-9d50-b29cab8c39b0.svg',
    'imgIconLeaf1': 'assets/figma/e809b16d-75bb-4545-b163-455eb6424db0.svg',
    'imgIconBack': 'assets/figma/2000a418-36f2-4aea-9b71-dc84a7b2a352.svg',
    'imgIconPalette': 'assets/figma/c587c560-eea0-4416-81dd-cc7f62a7e3d9.svg',
    'imgIconLeaf2': 'assets/figma/0a8b239d-3f5e-42e2-9ce7-6d251eb21fb2.svg',
  },
  'sad': {
    'imgIconLeaf': 'assets/figma/62cc8eb1-937d-4aa7-a97c-b0cf6bd7780e.svg',
    'imgThemeMotifSad': 'assets/figma/acc268fc-495e-456b-abe9-b2ea66d97252.svg',
    'imgIconBack': 'assets/figma/251209a3-e668-409b-bc94-80e6a36a3ffe.svg',
    'imgIconChevron': 'assets/figma/317ab1dd-8189-4c92-abe2-828aa286831a.svg',
    'imgActivityDot': 'assets/figma/7a1ff8ec-c87c-4027-8d3a-74145f073ae1.svg',
    'imgIconCamera': 'assets/figma/ca4fe37a-e7a7-47e9-a117-0f49a798ca60.svg',
    'imgIconArchive': 'assets/figma/b2e7f8a4-ca93-4972-b0e2-4d206f065aee.svg',
    'imgIconHome': 'assets/figma/1bd9ea82-d254-48cb-ac6c-4358847d2118.svg',
    'imgIconLeaf1': 'assets/figma/53e4439f-dcdb-431b-a043-63ea24ae2fa1.svg',
    'imgIconHeart': 'assets/figma/9284a818-e70e-4f7d-a474-56b79ca511e5.svg',
    'imgIconSettings': 'assets/figma/de776195-bdb2-4118-9318-0ec06b3a1feb.svg',
  },
  'energetic': {
    'imgIconLeaf': 'assets/figma/8784ab7b-7351-43e0-868e-735327ae053c.svg',
    'imgThemeMotifEnergetic':
        'assets/figma/b1629bd3-75ea-4968-bd3d-750184720897.svg',
    'imgIconBack': 'assets/figma/9174b1d0-04ef-49fe-9d5a-01cb91d3d201.svg',
    'imgIconChevron': 'assets/figma/f11a68e2-0cae-4711-9f37-4011f59e0c5b.svg',
    'imgActivityDot': 'assets/figma/08491845-9e91-4e55-9517-05bbc94958af.svg',
    'imgIconCamera': 'assets/figma/c892a7cc-51c5-4b6b-ae3e-6fb7dca236aa.svg',
    'imgIconArchive': 'assets/figma/de34a8ee-56cf-4004-a632-1057b0f7dc97.svg',
    'imgIconHome': 'assets/figma/06276a0e-e285-4794-9c92-f9a10dc1f727.svg',
    'imgIconLeaf1': 'assets/figma/36a1f6b8-76fe-4bf4-80b8-995faa98981c.svg',
    'imgIconHeart': 'assets/figma/5f1c400a-1a37-4dfc-8347-782d44f1d9ce.svg',
    'imgIconSettings': 'assets/figma/6f03a610-fea0-4bf5-ba1a-8e0a180d38a3.svg',
  },
  'groups': {
    'imgIconHome': 'assets/figma/37d59125-7b7b-4b44-a5ba-70a6dd43fc8f.svg',
    'imgIconLeaf': 'assets/figma/411046b2-d9c1-447e-bfa8-801e20be30e5.svg',
    'imgIconHeart': 'assets/figma/cc062e27-3db2-4d17-b84b-0bd2a4ea06ee.svg',
    'imgIconSettings': 'assets/figma/0b3e0f89-42e9-47d2-a77f-d7e2e237a532.svg',
    'imgIconLeaf1': 'assets/figma/62e0d32c-b52c-4921-8693-0730e2055155.svg',
    'imgIconUsers': 'assets/figma/8f5b0dbc-3968-4445-9d66-41794c233a7b.svg',
  },
  'signin': {
    'imgIconLeaf': 'assets/figma/6ac8e1ed-8562-4173-b816-9b9b08e89bdb.svg',
    'imgThemeMotifLight':
        'assets/figma/89e10461-6f69-499c-8d28-1b959ccc3ebd.svg',
    'imgIconEye': 'assets/figma/f8a0f329-720d-4f09-ae49-4243965ac721.svg',
  },
  'conversation': {
    'imgIconHome': 'assets/figma/4f4603a4-36aa-4457-8568-a038ca610e62.svg',
    'imgIconLeaf': 'assets/figma/8748bf21-69af-4f5d-b71d-7625a7d41d54.svg',
    'imgIconHeart': 'assets/figma/27e8471a-5128-4119-bc19-8b9878219fd2.svg',
    'imgIconSettings': 'assets/figma/860dc86a-c40f-4386-a4f9-dea68520236b.svg',
    'imgIconLeaf1': 'assets/figma/5643300a-5fd6-4411-a61c-8ee58706cdf6.svg',
    'imgIconBack': 'assets/figma/b739fc71-e975-435f-ac4f-e49f192ddb78.svg',
    'imgIconSend': 'assets/figma/f9a29a47-274b-4c09-b134-f91defbccc7c.svg',
  },
  'events': {
    'imgIconHome': 'assets/figma/bc9426e2-970e-40c0-b6b1-51f7602aa876.svg',
    'imgIconLeaf': 'assets/figma/3cf85fd3-7586-409d-bee6-00e419b32906.svg',
    'imgIconHeart': 'assets/figma/052a7c1c-8d9b-475a-85e7-15f474c9e45a.svg',
    'imgIconSettings': 'assets/figma/f01f4ca5-2a55-4d6a-aac8-5b9abdc231db.svg',
    'imgIconLeaf1': 'assets/figma/f49c599e-6117-467f-8646-d142b5216fb4.svg',
  },
  'profile': {
    'imgIconHome': 'assets/figma/b89115fa-a226-4bad-852a-fb65829fc0c7.svg',
    'imgIconLeaf': 'assets/figma/f362ee11-399d-4fb7-8377-a284ddf9cfb5.svg',
    'imgIconHeart': 'assets/figma/f01763f1-55fe-4c10-8d0b-6bc8013332db.svg',
    'imgIconSettings': 'assets/figma/a125dd8e-1102-4ecf-b8da-7339d4fa9850.svg',
    'imgIconLeaf1': 'assets/figma/360d6de8-6390-41bc-8c60-903e30e42724.svg',
    'imgIconBack': 'assets/figma/b75ab9fa-d25a-44f1-b3c5-c9759cb37d1e.svg',
    'imgColor0': 'assets/figma/44a1cddc-8661-4a08-936f-178170c6deeb.svg',
    'imgColor1': 'assets/figma/0b53b253-f1b6-45b6-ad34-19883b148951.svg',
    'imgColor2': 'assets/figma/c6689c39-e7bd-4f75-99f4-9b1b84c458df.svg',
    'imgColor3': 'assets/figma/2d1983c4-a302-4e6d-9f82-6239b63440c6.svg',
    'imgColor4': 'assets/figma/9d5fd5a8-4a6d-4bbb-8b3a-cb10031e676f.svg',
    'imgColor5': 'assets/figma/1c48de69-6213-444c-a52f-420f3ab28c58.svg',
  },
  'people': {
    'imgIconHome': 'assets/figma/2a56f833-39f4-4868-846f-99da6de5135a.svg',
    'imgIconLeaf': 'assets/figma/2fdfece1-08e0-4142-86c5-5f91a88dea4c.svg',
    'imgIconHeart': 'assets/figma/c2fc1e40-c701-4595-908b-286bc2413a51.svg',
    'imgIconSettings': 'assets/figma/061fa1e0-6dc2-4771-ac40-12ee31902247.svg',
    'imgIconLeaf1': 'assets/figma/d8ac6f2d-e7db-4248-b1a6-bccbfc449673.svg',
  },
  'create': {
    'imgIconHome': 'assets/figma/07c8f194-13d7-442e-9aeb-52f1189d5b80.svg',
    'imgIconLeaf': 'assets/figma/66ad8327-c342-4891-8d35-f50af72dcab2.svg',
    'imgIconHeart': 'assets/figma/71989dc5-5875-43b7-8067-de18f5711d7b.svg',
    'imgIconSettings': 'assets/figma/108b0616-4ebf-4c96-8ef1-956925d9fe4b.svg',
    'imgIconLeaf1': 'assets/figma/88b743ed-953e-4728-93aa-22e39f06e901.svg',
    'imgIconClose': 'assets/figma/6780d502-edd7-49b0-b0d9-d41e93d96ec0.svg',
    'imgIconLeaf2': 'assets/figma/8bc52828-4238-455f-be8a-5ae22ad1c1fd.svg',
    'imgIconLeaf3': 'assets/figma/6e07165c-e46f-4b27-bd72-560512b0a936.svg',
    'imgIconCamera': 'assets/figma/44fa6e0c-1b21-41ca-9bab-86fed92c5312.svg',
    'imgIconMusic': 'assets/figma/41fc9f8e-b1e0-4d5c-a441-df92233a5b43.svg',
    'imgIconPalette': 'assets/figma/e6c21c41-c2e5-442f-9091-f90c2628d50d.svg',
    'imgIconBall': 'assets/figma/c64f182b-0e71-4950-a008-cb66bf7f0e6a.svg',
    'imgIconBook': 'assets/figma/8d6a212a-6dad-46c3-8251-23539abbc9b1.svg',
    'imgIconFlower': 'assets/figma/be03a039-8ef6-41c8-a832-b45fc008f18b.svg',
    'imgIconChef': 'assets/figma/792142fa-897a-4896-ac35-3d9b56b42d13.svg',
    'imgIconFitness': 'assets/figma/9c3eb562-8f67-40c3-ab41-f99ec5248148.svg',
    'imgIconLaptop': 'assets/figma/cddd865b-1dfa-4702-b7c7-8bfa2a2046cd.svg',
    'imgIconChess': 'assets/figma/3425b531-0a5f-4671-a2d0-94754741f571.svg',
    'imgIconSend': 'assets/figma/f82d4dc6-7abd-44cb-b4e2-5fdaf4b1ac3f.svg',
    'imgColor0': 'assets/figma/a269c467-95ec-47f2-ab68-348377fda37b.svg',
    'imgColor1': 'assets/figma/c3a836a7-b67b-464a-99e5-aaf899ca3e05.svg',
    'imgColor2': 'assets/figma/396e7352-87d7-45a2-8aa7-18afd36e6ed1.svg',
    'imgColor3': 'assets/figma/1bc2bb3b-fa75-4144-8ae5-61e00504bffc.svg',
    'imgColor4': 'assets/figma/f7bbdf45-64b6-4e5e-8501-81ff7a350de1.svg',
    'imgColor5': 'assets/figma/53c33fd0-99c9-4fd0-a471-70981c6285b3.svg',
  },
  'signout': {
    'imgIconHome': 'assets/figma/c00ee546-fc00-40e8-8314-3f8d5e1b4cec.svg',
    'imgIconLeaf': 'assets/figma/bf07098a-3017-491b-a249-d6aa6233576f.svg',
    'imgIconHeart': 'assets/figma/c131ceaf-6358-4050-af38-b16ed4b2966a.svg',
    'imgIconSettings': 'assets/figma/4438d9c7-0a21-44d7-bd0b-acfaf0474cf0.svg',
    'imgIconLeaf1': 'assets/figma/efb0b21a-746a-4e00-bfab-d3fc759b775b.svg',
    'imgIconEdit': 'assets/figma/27ea4350-52c7-408d-acf5-63a257acc264.svg',
    'imgIconUser': 'assets/figma/6f701cae-ad2d-43ff-9a79-00687bb6ef0c.svg',
    'imgIconChevron': 'assets/figma/bee729e3-9b16-4122-9037-dd80e24c922a.svg',
    'imgIconHeadphones':
        'assets/figma/564e6632-0cd7-4742-afb8-80cd5265333b.svg',
    'imgIconBell': 'assets/figma/b21e89b7-37eb-420f-9190-0e8b24b4bc79.svg',
    'imgIconClock': 'assets/figma/97c5ae36-4f70-4a40-b596-3d5408855a8e.svg',
    'imgIconPalette': 'assets/figma/606a5736-5657-45f4-9e9e-401b77fb0990.svg',
    'imgIconLock': 'assets/figma/edb57d54-f5fd-4f32-bd89-7f83d19db383.svg',
    'imgIconClose': 'assets/figma/24c21186-ab53-40aa-b847-3901b665b7fc.svg',
  },
  'hobbies': {
    'imgIconHome': 'assets/figma/fc0fdb95-44f0-46af-baf3-b42398bada71.svg',
    'imgIconLeaf': 'assets/figma/5b82e78a-5840-4937-b14d-825c8e574eb5.svg',
    'imgIconHeart': 'assets/figma/d00db9bc-1b1d-4660-8d87-94b401753f39.svg',
    'imgIconSettings': 'assets/figma/0af63e47-dc4e-4b9b-8eee-55a46b18a27d.svg',
    'imgIconLeaf1': 'assets/figma/16303490-c438-4d21-bd0d-3abad85c79d7.svg',
    'imgIconLeaf2': 'assets/figma/a44af9ac-35a4-4fdc-8f48-261b3c302f46.svg',
  },
  'privacy': {
    'imgIconHome': 'assets/figma/d063008f-2477-48e5-9b65-43b103fe4625.svg',
    'imgIconLeaf': 'assets/figma/c54ceda3-e931-4aab-aa58-ffe2ebf10353.svg',
    'imgIconHeart': 'assets/figma/af44d994-65c8-45ed-9b14-0fb6a1b3cc34.svg',
    'imgIconSettings': 'assets/figma/7a98935d-bbf4-4330-9a68-5ea6a6a6bff3.svg',
    'imgIconLeaf1': 'assets/figma/dd800f87-195b-46c5-98c6-4816d02663db.svg',
    'imgIconBack': 'assets/figma/9735dc89-6f3e-402d-b6e4-b3e3a2429e31.svg',
  },
  'dark': {
    'imgIconLeaf': 'assets/figma/eabc883f-43c9-4c88-9363-e1587c6afedd.svg',
    'imgThemeMotifDark':
        'assets/figma/a9cac432-d73c-4f2c-b9ac-552f5283049f.svg',
    'imgIconBack': 'assets/figma/890a0c8d-2105-4318-aad0-aa10badb8557.svg',
    'imgIconChevron': 'assets/figma/dc9f197f-6d82-4e9b-ab8e-4a6ad0f413a0.svg',
    'imgActivityDot': 'assets/figma/565b1aa8-c197-49de-af71-66ebedca6998.svg',
    'imgIconCamera': 'assets/figma/253cd703-8519-4c80-891a-b90f444eece1.svg',
    'imgIconArchive': 'assets/figma/f884acd7-1056-489f-bb53-d6df0b412fbb.svg',
    'imgIconHome': 'assets/figma/96085e08-0ff5-4393-a5a0-aee4385082d6.svg',
    'imgIconLeaf1': 'assets/figma/79adf6f9-5084-4afc-bec1-086d0fd42729.svg',
    'imgIconHeart': 'assets/figma/ad87af49-f252-466e-98b6-a018455f0dee.svg',
    'imgIconSettings': 'assets/figma/07286f29-4ffe-4441-a782-d29f2849c1b9.svg',
  },
  'hyper': {
    'imgIconHome': 'assets/figma/a0818cc2-f0cc-485b-8493-eb7f52cd4997.svg',
    'imgIconLeaf': 'assets/figma/53a01d2c-b593-4363-9737-9451dd167ebd.svg',
    'imgIconHeart': 'assets/figma/2d5710c8-46b9-47ab-ab57-bf19e3d11222.svg',
    'imgIconSettings': 'assets/figma/0c3f5ee7-e272-4e10-bd31-0d4155ec8185.svg',
    'imgIconLeaf1': 'assets/figma/2c9cc9e2-2ff7-45f2-9150-6ed23732ef63.svg',
    'imgIconBack': 'assets/figma/bacb74a1-85d7-46ec-9b3b-d69a092fbe65.svg',
    'imgIconHeadphones':
        'assets/figma/10b37b5d-808d-4f8b-9bd9-60adaa75b07b.svg',
    'imgIconSearch': 'assets/figma/f0179f4d-01f9-4cf1-b1dd-37f3c2fb85e4.svg',
  },
  'appearance': {
    'imgIconHome': 'assets/figma/580784f9-441c-4423-9962-4a56b38be617.svg',
    'imgIconLeaf': 'assets/figma/0a29cef6-3b40-48c0-864a-4650f8474d93.svg',
    'imgIconHeart': 'assets/figma/fad30fd4-318c-4e81-84eb-0cf940f1863e.svg',
    'imgIconSettings': 'assets/figma/a4ff092b-b06f-4802-ab4c-cff5a4cbc2dd.svg',
    'imgIconLeaf1': 'assets/figma/9b4ad8cf-1e11-4134-9b9a-28a69118048b.svg',
    'imgIconBack': 'assets/figma/ec0f1e05-73ab-4f11-a17d-504f5b645adb.svg',
  },
  'apps': {
    'imgIconHome': 'assets/figma/8890d024-d157-4bb8-967c-b233b4c15502.svg',
    'imgIconLeaf': 'assets/figma/878cc420-4003-4a65-ba7f-386519b28291.svg',
    'imgIconHeart': 'assets/figma/058dccd6-427f-45dd-99bb-6978732b3205.svg',
    'imgIconSettings': 'assets/figma/747e8809-681d-4f98-9a65-f3033d1de937.svg',
    'imgIconLeaf1': 'assets/figma/36ef26d2-c7e7-4bae-a3ac-4d23ea8af113.svg',
    'imgIconBack': 'assets/figma/2fe34664-13c9-4d67-bbd7-f192bf771e8e.svg',
  },
};

class FigmaIcon extends StatelessWidget {
  const FigmaIcon(
    this.name, {
    super.key,
    this.size = 24,
    this.color,
    this.screen = 'home',
  });
  final String name, screen;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final path = figmaAssets[screen]?[name] ?? figmaAssets['home']?[name];
    assert(path != null, 'Missing Figma asset: $screen/$name');
    return SvgPicture.asset(
      path!,
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
      excludeFromSemantics: true,
    );
  }
}

class ThemeMotif extends StatelessWidget {
  const ThemeMotif({super.key, this.size = 100});
  final double size;
  @override
  Widget build(BuildContext context) {
    final name = switch (context.figmaStyle.variant) {
      AppThemeVariant.rainyDay => 'rainy',
      _ => context.figmaStyle.variant.name,
    };
    final map = figmaAssets[name]!;
    final key = map.keys.firstWhere((k) => k.startsWith('imgThemeMotif'));
    return FigmaIcon(key, screen: name, size: size);
  }
}
