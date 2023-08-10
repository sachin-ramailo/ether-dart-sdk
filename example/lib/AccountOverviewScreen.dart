import 'package:flutter/material.dart';
import 'package:sdk/account.dart';
import 'package:sdk/gsnClient/network_config/network_config_mumbai.dart';
import 'package:sdk/networks/evm_networks.dart';
import 'package:url_launcher/url_launcher.dart';

// const RlyNetwork = RlyMumbaiNetwork;

class AccountOverviewScreen extends StatefulWidget {
  final String rlyAccount;

  AccountOverviewScreen({required this.rlyAccount});

  @override
  _AccountOverviewScreenState createState() => _AccountOverviewScreenState();
}

class _AccountOverviewScreenState extends State<AccountOverviewScreen> {
  bool loading = false;
  double? balance;
  String transferBalance = '';
  String transferAddress = '';
  String? mnemonic;

  void fetchBalance() async {
    setState(() {
      loading = true;
    });

    // double bal = await RlyNetwork.getBalance();

    setState(() {
      balance = 0.0;
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchBalance();
  }

  void claimRlyTokens() async {
    setState(() {
      loading = true;
    });

    // await RlyNetwork.claimRly();

    fetchBalance();
  }

  void transferTokens() async {
    setState(() {
      loading = true;
    });

    await transfer(
      transferAddress,
      double.parse(transferBalance),
      mumbaiNetworkConfig,
    );

    fetchBalance();

    setState(() {
      transferBalance = '';
      transferAddress = '';
      loading = false;
    });
  }

  void deleteAccount() async {
    // await permanentlyDeleteAccount();
  }

  void revealMnemonic() async {
    String? value = await AccountsUtil.getInstance().getAccountPhrase();
    if (value == null || value.isEmpty) {
      throw 'Something went wrong, no Mnemonic when there should be one';
    }

    setState(() {
      mnemonic = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Text('Welcome to RLY'),
              const SizedBox(height: 12),
              Text(widget.rlyAccount.isNotEmpty
                  ? widget.rlyAccount
                  : 'No Account Exists'),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text('Your Current Balance Is'),
                      Text(balance?.toString() ?? 'Loading...'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          await launchUrl(Uri.parse(
                              'https://mumbai.polygonscan.com/address/${widget.rlyAccount}'));
                        },
                        child: Text('View on Polygon'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text('What Would You Like to Do?'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: claimRlyTokens,
                        child: Text('Register My Account'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: transferTokens,
                        child: Text('Transfer RLY'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: revealMnemonic,
                        child: Text('Export Your Account'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: deleteAccount,
                        child: Text('Delete Your Account'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text('Copy The Phrase below to export your wallet'),
                      const SizedBox(height: 12),
                      Text(mnemonic ?? ''),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            mnemonic = null;
                          });
                        },
                        child: Text('Close'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              loading ? CircularProgressIndicator() : SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}
