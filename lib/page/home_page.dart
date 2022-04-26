import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3dart/web3dart.dart';

import '../abi/stream_chicken_2.g.dart';
import '../helper/wallet_connect_helper.dart';
import '../model/app_info.dart';
import '../model/crypto_wallet.dart';
import '../wallect_connect/wallet_connect_ethereum_credentials.dart';
import '../widget/my_textfield.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String ethRinkebyTestnetEndpoints = 'https://rinkeby.infura.io/v3/e3090e47c3624aa3aa126fa7297bff9b';

  final WalletConnectHelper walletConnectHelper = WalletConnectHelper(
    appInfo: AppInfo(
      name: "Mobile App",
      url: "https://example.mobile.com",
    ),
  );

  bool isConnectWallet = false;
  String publicWalletAddress = "";

  late Web3Client web3client;
  late StreamChicken2Contract contract;

  final TextEditingController fromAddressEditController = TextEditingController();
  final TextEditingController toAddressEditController = TextEditingController();
  final TextEditingController tokenIdEditController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void connectWallet() async {
    isConnectWallet = await walletConnectHelper.initSession();
    if (isConnectWallet) {
      // update ui
      setState(() {
        publicWalletAddress = walletConnectHelper.accounts.first;
      });

      // init
      initWeb3Client();
      initContract();
      fromAddressEditController.text = walletConnectHelper.getEthereumCredentials().getEthereumAddress().toString();
      toAddressEditController.text = '0x3D7BAD4D04eE46280E29B5149EE1EAa0d5Ff649F'.toLowerCase();
    }
  }

  void disconnectWallet() {
    walletConnectHelper.dispose();
    isConnectWallet = false;
    publicWalletAddress = '';
    tokenIdEditController.text = '';
    setState(() {});
  }

  void initWeb3Client() {
    web3client = Web3Client(ethRinkebyTestnetEndpoints, Client());
  }

  void initContract() {
    // use contract(StreamChicken2) address
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
    try {
      // check input value string
      String fromString = fromAddressEditController.text;
      String toString = toAddressEditController.text;
      String tokenIdString = tokenIdEditController.text;
      if (fromString.isEmpty || toString.isEmpty) {
        Fluttertoast.showToast(msg: 'Please input address');
        return;
      } else if (tokenIdString.isEmpty) {
        Fluttertoast.showToast(msg: 'Please input tokenId');
        return;
      }

      // covert to correct type
      EthereumAddress fromAddress = EthereumAddress.fromHex(fromString);
      EthereumAddress toAddress = EthereumAddress.fromHex(toString);
      int tokenId = int.parse(tokenIdString);

      // help users navigating to Metamask app for pressing button
      await launch(CryptoWallet.metamask.universalLink, forceSafariVC: false);

      // transfer
      final WalletConnectEthereumCredentials credentials = walletConnectHelper.getEthereumCredentials();
      try {
        final String transferResult = await contract.safeTransferFrom(
          fromAddress,
          toAddress,
          BigInt.from(tokenId),
          credentials: credentials,
          transaction: Transaction(
            from: fromAddress,
            to: toAddress,
          ),
        );
        Fluttertoast.showToast(msg: 'Transfer successfully\n$transferResult');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Transfer failed - $e');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "transferNFT() - failure - $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
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
      ),
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
                  onPressed: () => getContractOwnerAddress(),
                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.orange)),
                  child: const Text(
                    'Get owner address',
                    style: TextStyle(fontSize: 24.0),
                  ),
                ),
                Column(
                  children: [
                    MyTextField(
                      textEditingController: fromAddressEditController,
                      hint: 'from address',
                      inputBorder: const OutlineInputBorder(),
                    ),
                    MyTextField(
                      textEditingController: toAddressEditController,
                      hint: 'to address',
                      inputBorder: const OutlineInputBorder(),
                      keyboardType: TextInputType.text,
                    ),
                    MyTextField(
                      textEditingController: tokenIdEditController,
                      hint: 'token id (#1)',
                      inputBorder: const OutlineInputBorder(),
                      keyboardType: TextInputType.number,
                    ),
                    ElevatedButton(
                      onPressed: () => transferNFT(),
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
