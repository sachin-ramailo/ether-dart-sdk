import 'package:sdk/gsnClient/ABI/IRelayHubData.dart';
import 'package:web3dart/web3dart.dart';

import 'IForwarderData.dart';

DeployedContract forwarderContractGetNonceFunction(
    EthereumAddress contractAddress) {
  return DeployedContract(
    ContractAbi.fromJson(
      '[{"constant": false,"inputs": ${getIForwarderABIData()}]', // Add the ABI of the relay hub contract here
      'getNonce', // Add the contract name here
    ),
    contractAddress,
  );
}
