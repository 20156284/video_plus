// ===============================================
// default_player
//
// Create by Will on 2023/11/17 22:49
// Copyright Will All rights reserved.
// ===============================================

import 'package:flutter/widgets.dart';
import 'package:video_plus/video_plus.dart';
import 'package:video_plus_example/utils/mock_data.dart';

class DefaultPlayer extends StatelessWidget {
  const DefaultPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: VideoPlusView(
        control: PlusControl(
          url: mockData['items'][0]['trailer_url'],
          // decryptM3U8: PlatformAwareCrypto.decryptM3U8,
          // encry: PlatformAwareCrypto.encry,
          useCache: true,
        ),
      ),
    );
  }
}
