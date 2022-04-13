import 'package:dart_web3/dart_web3.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

import '../abi/stream_chicken_2.g.dart';
import '../helper/wallet_connect_helper.dart';
import '../model/app_info.dart';
import '../model/web3_wallet.dart';
import '../wallect_connect/wallet_connect_ethereum_credentials.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String ethRinkebyTestnetEndpoints = 'https://rinkeby.infura.io/v3/e3090e47c3624aa3aa126fa7297bff9b';

  final WalletConnectHelper walletConnectHelper = WalletConnectHelper(
    AppInfo(
      name: "Mobile App",
      url: "https://example.mobile.com",
    ),
  );

  bool isConnectWallet = false;
  String publicWalletAddress = "";

  late Web3Client web3client;
  late StreamChicken2Contract contract;

  @override
  void initState() {
    super.initState();
  }

  void connectWallet() async {
    isConnectWallet = await walletConnectHelper.initSession();
    if (isConnectWallet) {
      publicWalletAddress = walletConnectHelper.accounts.first;
      setState(() {});

      initWeb3Client();
      initContract();
    }
  }

  void disconnectWallet() {
    walletConnectHelper.dispose();
    isConnectWallet = false;
    publicWalletAddress = '';
    setState(() {});
  }

  void initWeb3Client() {
    web3client = Web3Client(ethRinkebyTestnetEndpoints, Client());
  }

  void initContract() {
    final EthereumAddress contractAddress = EthereumAddress.fromHex('0xa1e767940e8fb953bbd8972149d2185071b86063');
    // use Rinkeby(test-chain), chain id is '4'
    contract = StreamChicken2Contract(address: contractAddress, client: web3client, chainId: 4);
  }

  /// get nft-contract name
  Future<void> getContractName() async {
    String name = await contract.name();
    Fluttertoast.showToast(msg: name);
  }

  /// get nft-contract owner address
  Future<void> getContractOwnerAddress() async {
    EthereumAddress ownerAddress = await contract.owner();
    Fluttertoast.showToast(msg: "$ownerAddress");
  }

  /// transfer nft to specific user
  Future<void> transferNFT() async {
    // help users navigating to Metamask app for pressing button
    await launch(Web3Wallet.metamask.universalLink, forceSafariVC: false);
    // transfer
    final WalletConnectEthereumCredentials credentials = walletConnectHelper.getEthereumCredentials();
    try {
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
      Fluttertoast.showToast(msg: 'Transfer successfully\n$transferResult');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Transfer failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo'),
        actions: [
          if (isConnectWallet)
            IconButton(
              icon: const Icon(Icons.exit_to_app_rounded),
              onPressed: () => disconnectWallet(),
            ),
        ],
      ),
      body: !isConnectWallet ? _buildDisconnectView() : _buildConnectedView(),
    );
  }

  Widget _buildDisconnectView() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image.asset(
          'assets/metamask.png',
          width: 250.0,
        ),
        const SizedBox(height: 16.0),
        TextButton(
          onPressed: () => connectWallet(),
          child: const Text(
            'Connect',
            style: TextStyle(fontSize: 30.0),
          ),
        ),
      ]),
    );
  }

  Widget _buildConnectedView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset('assets/metamask.png', width: 60.0),
              const SizedBox(width: 16.0),
              Expanded(
                child: Text(
                  publicWalletAddress,
                  style: const TextStyle(color: Colors.black),
                ),
              )
            ],
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => getContractName(),
                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.orange)),
                  child: const Text(
                    'Get name',
                    style: TextStyle(fontSize: 24.0),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => getContractName(),
                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.orange)),
                  child: const Text(
                    'Get owner address',
                    style: TextStyle(fontSize: 24.0),
                  ),
                ),
                Column(
                  children: [
                    TextField(),
                    ElevatedButton(
                      onPressed: () => getContractName(),
                      style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.orange)),
                      child: const Text(
                        'Transfer NFT',
                        style: TextStyle(fontSize: 24.0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
