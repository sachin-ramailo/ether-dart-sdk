import 'package:sdk/contracts/tokenFaucetData.dart';
import 'package:sdk/gsnClient/network_config/network_config_mumbai.dart';
import 'package:web3dart/web3dart.dart';

import '../network_config/network_config.dart';

DeployedContract tokenFaucet(NetworkConfig config, EthereumAddress signer) {
  return DeployedContract(
      ContractAbi.fromJson(getTokenFaucetDataJson()["abi"], "TokenFaucet"),
      signer);
}
