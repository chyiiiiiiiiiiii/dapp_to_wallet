import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

import '../model/app_info.dart';
import '../util/deeplink_util.dart';
import '../wallect_connect/wallet_connect_ethereum_credentials.dart';
import '../model/web3_wallet.dart';

typedef OnSessionUriCallback = void Function(String uri);

/// WalletConnectHelper is an object for implement WalletConnect protocol for
/// mobile apps using deep linking to connect with wallets.
class WalletConnectHelper {
  final WalletConnect connector;
  // mobile app info
  final AppInfo? appInfo;

  SessionStatus? sessionStatus;
  String displayUri = '';

  List<String> accounts = [];

  WalletConnectHelper._internal({
    required this.connector,
    required this.appInfo,
  });

  /// Connector using brigde 'https://bridge.walletconnect.org' by default.
  factory WalletConnectHelper(AppInfo? appInfo, {String? bridge}) {
    final connector = WalletConnect(
      bridge: bridge ?? 'https://bridge.walletconnect.org',
      clientMeta: PeerMeta(
        name: appInfo?.name ?? 'WalletConnect',
        description: appInfo?.description ?? 'WalletConnect Developer App',
        url: appInfo?.url ?? 'https://walletconnect.org',
        icons: appInfo?.icons ?? ['https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'],
      ),
    );

    return WalletConnectHelper._internal(
      connector: connector,
      appInfo: appInfo,
    );
  }

  //----------------------------------------------------------------

  Future<void> initSession({int? chainId}) async {
    if (!connector.connected) {
      sessionStatus = await connector.createSession(
        chainId: chainId,
        onDisplayUri: (uri) {
          displayUri = uri;
        },
      );
      if (sessionStatus == null) {
        debugPrint('createSession() - failure');
        return;
      }

      accounts = sessionStatus?.accounts ?? [];
    }
  }

  String _getDisplayUri() {
    return displayUri;
  }

  Future<void> connectWallet({
    Web3Wallet wallet = Web3Wallet.metamask,
  }) async {
    var deeplink = DeeplinkUtil.getDeeplink(wallet: wallet, uri: _getDisplayUri());
    bool isLaunch = await launch(deeplink, forceSafariVC: false);
    if (!isLaunch) {
      throw 'connectWallet() - failure - Could not open $deeplink.';
    }
  }

  Future<String> getPublicAddress({Web3Wallet wallet = Web3Wallet.metamask}) async {
    if (!connector.connected) {
      await initSession();
    }

    if (accounts.isNotEmpty) {
      final String address = accounts.first;
      return address;
    } else {
      throw 'Unexpected exception';
    }
  }

  /// 取得錢包地址
  WalletConnectEthereumCredentials getEthereumCredentials() {
    EthereumWalletConnectProvider provider = EthereumWalletConnectProvider(connector);
    WalletConnectEthereumCredentials credentials = WalletConnectEthereumCredentials(provider: provider);
    return credentials;
  }

  void dispose() {
    connector.killSession();

    sessionStatus = null;
    displayUri = '';

    accounts = [];
  }
}
