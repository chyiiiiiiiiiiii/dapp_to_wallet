/// Wallet Mobile app
/// universal link & deeplink should end with '/'
class Web3Wallet {
  static const Web3Wallet metamask = Web3Wallet(universalLink: 'https://metamask.app.link/', deeplink: 'metamask://');
  static const Web3Wallet trustWallet =
      Web3Wallet(universalLink: 'https://link.trustwallet.com/', deeplink: 'trust://');
  static const Web3Wallet rainbowMe = Web3Wallet(universalLink: 'https://rainbow.me/', deeplink: 'rainbow://');
  static const Web3Wallet talken = Web3Wallet(universalLink: 'https://talken.io');

  /// universal link for iOS
  final String universalLink;

  /// deeplink for android
  final String? deeplink;

  const Web3Wallet({
    required this.universalLink,
    this.deeplink,
  });
}
