import 'dart:typed_data';

import 'package:sdk/ethereum_utils.dart';

import 'package:sdk/utils/constants.dart';
import 'package:web3dart/web3dart.dart';

import 'account.dart';

void main() async {
  AccountsUtil accountsUtil = AccountsUtil.getInstance();
  // var account = accountsUtil.getAccountAddress();
  // final pKeyHex = accountsUtil.getPrivateKeyHex();
  // printLog("private key for new account = $pKeyHex");
  // printLog("Public address for new account = $account");
  var etherAmount = await accountsUtil.getBalance();
  printLog(
      "ether balance in gwei = ${etherAmount.getValueInUnit(EtherUnit.gwei)}");
  final wallet = await accountsUtil.getWallet();
  sendTokens(wallet, "0x7829222A97392EFcBc743531222CB71606d6f2b4");
  etherAmount = await accountsUtil.getBalance();
  printLog(
      "ether balance in gwei = ${etherAmount.getValueInUnit(EtherUnit.gwei)}");
}

extension ToString on Uint8List {
  String stringValue() {
    Uint8List uint8List = Uint8List.fromList(this); // Example Uint8List
    String convertedString = String.fromCharCodes(uint8List);
    return convertedString;
  }
}
