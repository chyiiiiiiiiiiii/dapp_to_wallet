import 'package:http/http.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:web3dart/web3dart.dart';

import 'wallet_connect_ethereum_credentials.dart';

abstract class TransactionTester {
  TransactionTester({required this.connector});

  final WalletConnect connector;

  Future<String> signTransaction(SessionStatus session);

  Future<String> signTransactions(SessionStatus session);

  Future<SessionStatus> connect({OnDisplayUriCallback? onDisplayUri});

  Future<void> disconnect();
}

class EthereumTransactionTester extends TransactionTester {
  final Web3Client ethereum;
  final EthereumWalletConnectProvider provider;

  EthereumTransactionTester._internal({
    required WalletConnect connector,
    required this.ethereum,
    required this.provider,
  }) : super(connector: connector);

  factory EthereumTransactionTester() {
    final ethereum = Web3Client('https://ropsten.infura.io/', Client());

    final connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      clientMeta: const PeerMeta(
        name: 'WalletConnect',
        description: 'WalletConnect Developer App',
        url: 'https://walletconnect.org',
        icons: ['https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'],
      ),
    );

    final provider = EthereumWalletConnectProvider(connector);

    return EthereumTransactionTester._internal(
      connector: connector,
      ethereum: ethereum,
      provider: provider,
    );
  }

  @override
  Future<SessionStatus> connect({OnDisplayUriCallback? onDisplayUri}) async {
    return connector.connect(chainId: 3, onDisplayUri: onDisplayUri);
  }

  @override
  Future<void> disconnect() async {
    await connector.killSession();
  }

  @override
  Future<String> signTransaction(SessionStatus session) async {
    final sender = EthereumAddress.fromHex(session.accounts[0]);

    final transaction = Transaction(
      to: sender,
      from: sender,
      gasPrice: EtherAmount.inWei(BigInt.one),
      maxGas: 100000,
      value: EtherAmount.fromUnitAndValue(EtherUnit.finney, 1),
    );

    final credentials = WalletConnectEthereumCredentials(provider: provider);

    // Sign the transaction
    final txBytes = await ethereum.sendTransaction(credentials, transaction);

    // Kill the session
    connector.killSession();

    return txBytes;
  }

  @override
  Future<String> signTransactions(SessionStatus session) {
    // TODO: implement signTransactions
    throw UnimplementedError();
  }
}
