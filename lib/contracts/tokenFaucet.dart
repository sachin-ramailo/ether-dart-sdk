import 'dart:convert';

import 'package:sdk/contracts/tokenFaucetData.dart';
import 'package:web3dart/web3dart.dart';

import '../network_config/network_config.dart';

DeployedContract tokenFaucet(NetworkConfig config, EthereumAddress signer) {
  final abi = getTokenFaucetDataJson()['abi'];

  return DeployedContract(
      ContractAbi.fromJson(jsonEncode(abi), "TokenFaucet"),
      signer);
}
