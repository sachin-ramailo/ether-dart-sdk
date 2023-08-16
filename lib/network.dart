import 'package:sdk/networks/evm_networks.dart';
import 'package:sdk/gsnClient/utils.dart';

import 'network_config/network_config_mumbai.dart';

abstract class Network {
  Future<double> getBalance({PrefixedHexString? tokenAddress});
  Future<String> transfer(
      String destinationAddress,
      double amount,
      {PrefixedHexString? tokenAddress, MetaTxMethod? metaTxMethod}
      );
    Future<String> claimRly();
  Future<String> registerAccount();
  Future<String> relay(GsnTransactionDetails tx);
  void setApiKey(String apiKey);
}
final Network RlyMumbaiNetwork = NetworkImpl(MumbaiNetworkConfig);
