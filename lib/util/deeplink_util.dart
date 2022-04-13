import 'dart:io';

import '../model/web3_wallet.dart';

class DeeplinkUtil {
  static const wcBridge = 'wc?uri=';

  static String getDeeplink({
    required Web3Wallet wallet,
    required String uri,
  }) {
    if (Platform.isIOS) {
      return wallet.universalLink + wcBridge + Uri.encodeComponent(uri);
    } else {
      return uri;
    }
  }
}
