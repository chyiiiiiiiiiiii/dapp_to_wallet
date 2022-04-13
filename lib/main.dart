import 'package:dart_web3/dart_web3.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3_wallet/model/web3_wallet.dart';

import 'abi/stream_chicken_2.g.dart';
import 'helper/wallet_connect_helper.dart';
import 'model/app_info.dart';
import 'wallect_connect/wallet_connect_ethereum_credentials.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Web3',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final WalletConnectHelper walletConnectHelper = WalletConnectHelper(
    AppInfo(
      name: "Mobile App",
      url: "https://example.mobile.com",
    ),
  );

  String publicAddress = "";

  @override
  void initState() {
    super.initState();

    init();
  }

  init() async {
    await walletConnectHelper.initSession();
    publicAddress = walletConnectHelper.accounts.first;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (publicAddress.isNotEmpty) ...{
              const Text("Public address in wallet:"),
              Text(
                publicAddress,
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            },
            TextButton(
              onPressed: () => connectWallet(),
              child: const Text('Connect Metamask'),
            ),
            TextButton(
              onPressed: () => sendTransaction(),
              child: const Text('Send transaction'),
            ),
          ],
        ),
      ),
    );
  }

  void connectWallet() {
    walletConnectHelper.connectWallet();
  }

  void disconnectWallect() {
    walletConnectHelper.dispose();
    publicAddress = '';
    setState(() {});
  }

  Future<void> sendTransaction() async {
    const String ethRinkebyTestnetEndpoints = 'https://rinkeby.infura.io/v3/e3090e47c3624aa3aa126fa7297bff9b';

    final Web3Client web3client = Web3Client(ethRinkebyTestnetEndpoints, Client());
    final WalletConnectEthereumCredentials credentials = walletConnectHelper.getEthereumCredentials();

    final EthereumAddress contractAddress = EthereumAddress.fromHex('0xa1e767940e8fb953bbd8972149d2185071b86063');
    StreamChicken2Contract contract = StreamChicken2Contract(address: contractAddress, client: web3client, chainId: 4);

    // get nft-contract name
    String name = await contract.name();
    debugPrint('name - $name');
    
    // get nft-contract owner address
    EthereumAddress ownerAddress = await contract.owner();
    debugPrint('ownerAddress - $ownerAddress');

    // help users navigating to Metamask app for pressing button
    await launch(Web3Wallet.metamask.universalLink, forceSafariVC: false);
    // transfer nft to specific user
    final String transferResult = await contract.safeTransferFrom(
      credentials.getEthereumAddress(),
      EthereumAddress.fromHex('0xA8831A1bCB54A4a2627BaF58b10Cd3352B2ae6BB'),
      BigInt.from(3),
      credentials: credentials,
      transaction: Transaction(
        from: credentials.getEthereumAddress(),
        to: EthereumAddress.fromHex('0xA8831A1bCB54A4a2627BaF58b10Cd3352B2ae6BB'),
      ),
    );
    debugPrint('transfer nft - $transferResult');
  }
}
