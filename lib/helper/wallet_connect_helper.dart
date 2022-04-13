import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

import '../model/app_info.dart';
import '../model/web3_wallet.dart';
import '../util/deeplink_util.dart';
import '../wallect_connect/wallet_connect_ethereum_credentials.dart';

typedef OnSessionUriCallback = void Function(String uri);

/// WalletConnectHelper is an object for implement WalletConnect protocol for
/// mobile apps using deep linking to connect with wallets.
class WalletConnectHelper {
  // mobile app info
  final AppInfo? appInfo;

  WalletConnect connector;

  SessionStatus? sessionStatus;

  List<String> accounts = [];

  WalletConnectHelper._internal({
    required this.connector,
    required this.appInfo,
  });

  /// Connector using brigde 'https://bridge.walletconnect.org' by default.
  factory WalletConnectHelper(AppInfo? appInfo, {String? bridge}) {
    final WalletConnect connector = WalletConnect(
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

  WalletConnect getWalletConnect({String? bridge}) {
    final WalletConnect connector = WalletConnect(
      bridge: bridge ?? 'https://bridge.walletconnect.org',
      clientMeta: PeerMeta(
        name: appInfo?.name ?? 'WalletConnect',
        description: appInfo?.description ?? 'WalletConnect Developer App',
        url: appInfo?.url ?? 'https://walletconnect.org',
        icons: appInfo?.icons ?? ['https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'],
      ),
    );
    return connector;
  }

  //----------------------------------------------------------------

  void reset() {
    connector = getWalletConnect();
  }

  Future<bool> initSession({int? chainId}) async {
    if (!connector.connected) {
      try {
        sessionStatus = await connector.createSession(
          chainId: chainId,
          onDisplayUri: (uri) async {
            await _connectWallet(displayUri: uri);
          },
        );

        accounts = sessionStatus?.accounts ?? [];

        return true;
      } catch (e) {
        debugPrint('createSession() - failure - $e');
        reset();
        return false;
      }
    } else {
      return true;
    }
  }

  Future<void> _connectWallet({Web3Wallet wallet = Web3Wallet.metamask, required String displayUri}) async {
    var deeplink = DeeplinkUtil.getDeeplink(wallet: wallet, uri: displayUri);
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

  Future<void> dispose() async {
    connector.session.reset();
    await connector.killSession();
    await connector.close();

    sessionStatus = null;
    accounts = [];

    reset();
  }
}
