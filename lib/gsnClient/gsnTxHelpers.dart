// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:web3dart/web3dart.dart';
//
// import 'network_config/network_config.dart';
//
// class GsnTransactionDetails {
//   final String from;
//   final String data;
//   final String to;
//   final String? value;
//   String? gas;
//   String maxFeePerGas;
//   String maxPriorityFeePerGas;
//   final String? paymasterData;
//   final String? clientId;
//
//   GsnTransactionDetails({
//     required this.from,
//     required this.data,
//     required this.to,
//     this.value,
//     this.gas,
//     required this.maxFeePerGas,
//     required this.maxPriorityFeePerGas,
//     this.paymasterData,
//     this.clientId,
//   });
// }
//
// class AccountKeypair {
//   final String privateKey;
//   final String address;
//
//   AccountKeypair({required this.privateKey, required this.address});
// }
//
// class RelayRequest {
//   final Map<String, dynamic> request;
//   final Map<String, dynamic> relayData;
//
//   RelayRequest({required this.request, required this.relayData});
// }
//
// Future<Map<String, dynamic>?> updateConfig(
//   NetworkConfig config,
//   GsnTransactionDetails transaction,
// ) async {
//   final response = await http.get(Uri.parse('${config.gsn.relayUrl}/getaddr'));
//   final data = json.decode(response.body);
//
//   if (data != null && data is Map) {
//     config.gsn.relayWorkerAddress = data['relayWorkerAddress'];
//     transaction.maxPriorityFeePerGas = data['minMaxPriorityFeePerGas'];
//     transaction.maxFeePerGas = config.gsn.chainId == '80001'
//         ? data['minMaxPriorityFeePerGas']
//         : data['maxMaxFeePerGas'].toString();
//   }
//
//   return {'config': config, 'transaction': transaction};
// }
//
// Future<RelayRequest?> buildRelayRequest(
//   GsnTransactionDetails transaction,
//   NetworkConfig config,
//   AccountKeypair account,
//   Web3Provider web3Provider,
// ) async {
//   if (transaction.gas != null) {
//     transaction.gas = estimateGasWithoutCallData(
//       transaction,
//       config.gsn.gtxDataNonZero,
//       config.gsn.gtxDataZero,
//     );
//   }
//
//   final secondsNow = DateTime.now().millisecondsSinceEpoch ~/ 1000;
//   final validUntilTime =
//       (secondsNow + config.gsn.requestValidSeconds).toString();
//
//   final senderNonce = await getSenderNonce(
//     account.address,
//     config.gsn.forwarderAddress,
//     web3Provider,
//   );
//
//   final relayRequest = RelayRequest(
//     request: {
//       'from': transaction.from,
//       'to': transaction.to,
//       'value': transaction.value ?? '0',
//       'gas': int.parse(transaction.gas!, radix: 16).toString(),
//       'nonce': senderNonce,
//       'data': transaction.data,
//       'validUntilTime': validUntilTime,
//     },
//     relayData: {
//       'maxFeePerGas': transaction.maxFeePerGas,
//       'maxPriorityFeePerGas': transaction.maxPriorityFeePerGas,
//       'transactionCalldataGasUsed': '',
//       'relayWorker': config.gsn.relayWorkerAddress,
//       'paymaster': config.gsn.paymasterAddress,
//       'forwarder': config.gsn.forwarderAddress,
//       'paymasterData': transaction.paymasterData?.toString() ?? '0x',
//       'clientId': '1',
//     },
//   );
//
//   final transactionCalldataGasUsed =
//       await estimateCalldataCostForRequest(relayRequest, config.gsn);
//
//   relayRequest.relayData['transactionCalldataGasUsed'] =
//       int.parse(transactionCalldataGasUsed, radix: 16).toString();
//
//   return relayRequest;
// }
//
// Future<Map<String, dynamic>?> buildRelayHttpRequest(
//   RelayRequest relayRequest,
//   NetworkConfig config,
//   AccountKeypair account,
//   Web3Provider web3Provider,
// ) async {
//   final signature = await signRequest(
//     relayRequest,
//     config.gsn.domainSeparatorName,
//     config.gsn.chainId,
//     account,
//   );
//
//   const approvalData = '0x';
//
//   final wallet = eth.VoidSigner(
//     relayRequest.relayData['relayWorker'],
//     web3Provider,
//   );
//   final relayLastKnownNonce = await wallet.getTransactionCount();
//   final relayMaxNonce = relayLastKnownNonce + config.gsn.maxRelayNonceGap;
//
//   final metadata = {
//     'maxAcceptanceBudget': config.gsn.maxAcceptanceBudget,
//     'relayHubAddress': config.gsn.relayHubAddress,
//     'signature': signature,
//     'approvalData': approvalData,
//     'relayMaxNonce': relayMaxNonce,
//     'relayLastKnownNonce': relayLastKnownNonce,
//     'domainSeparatorName': config.gsn.domainSeparatorName,
//     'relayRequestId': '',
//   };
//   final httpRequest = {
//     'relayRequest': relayRequest,
//     'metadata': metadata,
//   };
//
//   return httpRequest;
// }
//
// Future<String?> relayTransaction(
//   AccountKeypair account,
//   NetworkConfig config,
//   GsnTransactionDetails transaction,
// ) async {
//   final web3Provider = Web3Provider(
//       YourProvider()); // Replace YourProvider with the actual provider
//   final updatedConfig = await updateConfig(config, transaction);
//   final relayRequest = await buildRelayRequest(
//     updatedConfig['transaction'],
//     updatedConfig['config'],
//     account,
//     web3Provider,
//   );
//   final httpRequest = await buildRelayHttpRequest(
//     relayRequest,
//     updatedConfig['config'],
//     account,
//     web3Provider,
//   );
//
//   final relayRequestId = getRelayRequestID(
//     httpRequest['relayRequest'],
//     httpRequest['metadata']['signature'],
//   );
//
//   // Update request metadata with relayrequestid
//   httpRequest['metadata']['relayRequestId'] = relayRequestId;
//
//   final authHeader = {
//     'Authorization': 'Bearer ${config.relayerApiKey ?? ''}',
//   };
//
//   final res = await http.post(
//     Uri.parse('${config.gsn.relayUrl}/relay'),
//     headers: authHeader,
//     body: json.encode(httpRequest),
//   );
//   return handleGsnResponse(res, web3Provider);
// }
