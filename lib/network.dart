import 'package:sdk/networks/evm_networks.dart';
import 'package:web3dart/credentials.dart';
import 'package:sdk/gsnClient/utils.dart';

import 'network_config/network_config.dart';
import 'network_config/network_config_mumbai.dart';

abstract class Network {
  Future<double> getBalance([String? tokenAddress]);
  Future<String> transfer(String destinationAddress, double amount,
      [String? tokenAddress, MetaTxMethod? metaTxMethod]);
  Future<String> claimRly();
  Future<String> relay(GsnTransactionDetails tx);
  void setApiKey(String apiKey);
}

final Network RlyMumbaiNetwork = getEvmNetwork(MumbaiNetworkConfig);
