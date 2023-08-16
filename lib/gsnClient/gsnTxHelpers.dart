import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart' as convertLib;
import 'package:convert/convert.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:sdk/contracts/tokenFaucet.dart';
import 'package:sdk/gsnClient/ABI/IForwarder.dart';
import 'package:web3dart/crypto.dart';

import 'package:sdk/gsnClient/ABI/IRelayHub.dart';

import 'package:sdk/gsnClient/utils.dart';

import 'package:web3dart/web3dart.dart';

import '../network_config/network_config.dart';
import 'EIP712/ForwardRequest.dart';
import 'EIP712/RelayData.dart';
import 'EIP712/RelayRequest.dart';
import 'EIP712/typedSigning.dart';



  CalldataBytes calculateCalldataBytesZeroNonzero(String calldata) {
    final calldataBuf =
        Uint8List.fromList(convertLib.hex.decode(calldata.substring(2)));
    int calldataZeroBytes = 0;
    int calldataNonzeroBytes = 0;

    calldataBuf.forEach((ch) {
      ch == 0 ? calldataZeroBytes++ : calldataNonzeroBytes++;
    });

    return CalldataBytes(calldataZeroBytes, calldataNonzeroBytes);
  }

  int calculateCalldataCost(
    String msgData,
    int gtxDataNonZero,
    int gtxDataZero,
  ) {
    var calldataBytesZeroNonzero = calculateCalldataBytesZeroNonzero(msgData);
    return (calldataBytesZeroNonzero.calldataZeroBytes * gtxDataZero +
        calldataBytesZeroNonzero.calldataNonzeroBytes * gtxDataNonZero);
  }

  String estimateGasWithoutCallData(
    GsnTransactionDetails transaction,
    int gtxDataNonZero,
    int gtxDataZero,
  ) {
    final originalGas = transaction.gas;
    final callDataCost = calculateCalldataCost(
      transaction.data,
      gtxDataNonZero,
      gtxDataZero,
    );
    final adjustedGas = BigInt.parse(originalGas!) - BigInt.from(callDataCost);

    return '0x${adjustedGas.toRadixString(16)}';
  }

  Future<String> estimateCalldataCostForRequest(
      RelayRequest relayRequestOriginal, GSNConfig config) async {
    // Protecting the original object from temporary modifications done here
    var relayRequest = RelayRequest(
      request: ForwardRequest(
        from: relayRequestOriginal.request.from,
        to: relayRequestOriginal.request.to,
        value: relayRequestOriginal.request.value,
        gas: relayRequestOriginal.request.gas,
        nonce: relayRequestOriginal.request.nonce,
        data: relayRequestOriginal.request.data,
        validUntilTime: relayRequestOriginal.request.validUntilTime,
      ),
      relayData: RelayData(
        maxFeePerGas: relayRequestOriginal.relayData.maxFeePerGas,
        maxPriorityFeePerGas:
            relayRequestOriginal.relayData.maxPriorityFeePerGas,
        transactionCalldataGasUsed: '0xffffffffff',
        relayWorker: relayRequestOriginal.relayData.relayWorker,
        paymaster: relayRequestOriginal.relayData.paymaster,
        paymasterData:
            '0x${List.filled(config.maxPaymasterDataLength, 'ff').join()}',
        clientId: '0xffffffffff',
        forwarder: relayRequestOriginal.relayData.forwarder,
      ),
    );

    const maxAcceptanceBudget = '0xffffffffff';
    final signature = '0x${List.filled(65, 'ff').join()}';
    final approvalData =
        '0x${List.filled(config.maxApprovalDataLength, 'ff').join()}';

    final relayHub = relayHubContract(config.relayHubAddress);
    // Estimate the gas cost for the relayCall function call

    var relayRequestJson = jsonEncode(relayRequest.toJson());
    //todo: -> at other places in other files too, whereever there is a
    //function called on populateTransation field(in the rly sdk), instead of calling that
    //function itself(in dart files),we have to use this encodeCall to make a callable obejct
    //which will be used further in the code
    //for ex: here is is used in calculated the gas estimate in the next step

    final function = relayHub.function('relayHub');

    final tx =  Transaction.callContract(contract: relayHub, function: function, parameters: [ config.domainSeparatorName, maxAcceptanceBudget, relayRequestJson, signature,  approvalData]);
    if (tx == null || tx.data == null ||tx.data!.isEmpty) {
      throw 'tx not populated';
    }


    //todo: is the calculation of call data cost(from the rly sdk gsnTxHelper file)
    //similar to the estimate gas here?
    //TODO: remove this to string from next line
    return BigInt.from(calculateCalldataCost(tx.data.toString(), config.gtxDataNonZero, config.gtxDataZero)).toString();
  }

  Future<String> getSenderNonce(EthereumAddress sender,
      EthereumAddress forwarderAddress, Web3Client client) async {
    final forwarder = forwarderContractGetNonceFunction(forwarderAddress);

    final List<dynamic> result = await client.call(
      contract: forwarder,
      function: forwarder.function("getNonce"),
      params: [sender],
    );

    // TODO:- info explainer
    // Extract the nonce value from the result and convert it to a string
    // if you go to getNonce method of IForwarderData.dart
    //there is only one output defined in the getNonce method
    //that's why we can be sure that result[0] will be used here
    final nonce = (result[0] as BigInt).toString();
    return nonce;
  }

  Future<String> signRequest(
    RelayRequest relayRequest,
    String domainSeparatorName,
    String chainId,
    Wallet account,
  ) async {
    final cloneRequest = RelayRequest(
      request: ForwardRequest(
        from: relayRequest.request.from,
        to: relayRequest.request.to,
        value: relayRequest.request.value,
        gas: relayRequest.request.gas,
        nonce: relayRequest.request.nonce,
        data: relayRequest.request.data,
        validUntilTime: relayRequest.request.validUntilTime,
      ),
      relayData: RelayData(
        maxFeePerGas: relayRequest.relayData.maxFeePerGas,
        maxPriorityFeePerGas: relayRequest.relayData.maxPriorityFeePerGas,
        transactionCalldataGasUsed:
            relayRequest.relayData.transactionCalldataGasUsed,
        relayWorker: relayRequest.relayData.relayWorker,
        paymaster: relayRequest.relayData.paymaster,
        paymasterData: relayRequest.relayData.paymasterData,
        clientId: relayRequest.relayData.clientId,
        forwarder: relayRequest.relayData.forwarder,
      ),
    );

    final signedGsnData = TypedGsnRequestData(
      domainSeparatorName,
      int.parse(chainId),
      EthereumAddress.fromHex(relayRequest.relayData.forwarder),
      cloneRequest,
    );

    final signature = EthSigUtil.signTypedData(
      jsonData: jsonEncode(signedGsnData.message),
      privateKey: account.privateKey.toString(),
      version: TypedDataVersion.V1,
    );

    return signature;
  }

  String getRelayRequestID(
    Map<String, dynamic> relayRequest,
    String signature,
  ) {
    final types = ['address', 'uint256', 'bytes'];
    final parameters = [
      relayRequest['request']['from'],
      relayRequest['request']['nonce'],
      signature
    ];

    final hash = keccak256(AbiUtil.rawEncode(types, parameters));
    final rawRelayRequestId = hex.encode(hash).padLeft(64, '0');
    final prefixSize = 8;
    final prefixedRelayRequestId = rawRelayRequestId.replaceFirst(
        RegExp('^.{$prefixSize}'), '0' * prefixSize);
    return '0x$prefixedRelayRequestId';
  }

  Future<GsnTransactionDetails> getClaimTx(
    Wallet account,
    NetworkConfig config,
    Web3Client client,
  ) async {
    final faucet = tokenFaucet(
      config,
      EthereumAddress.fromHex(config.contracts.tokenFaucet),
    );

    final tx = faucet.function('claim').encodeCall([]);
    final gas = await client.estimateGas(
      sender: account.privateKey.address,
      data: tx,
    );

    //TODO:-> following code is inspired from getFeeData method of
    //abstract-provider of ethers js library
    //test if it exactly replicates the functions of getFeeData
    final EtherAmount gasPrice = await client.getGasPrice();
    final BigInt maxPriorityFeePerGas = BigInt.parse("1500000000");
    final maxFeePerGas =
        gasPrice.getInWei * BigInt.from(2) + (maxPriorityFeePerGas);
    final gsnTx = GsnTransactionDetails(
      from: account.privateKey.address.toString(),
      data: tx.toString(),
      value: EtherAmount.zero().toString(),
      to: faucet.address.hex,
      gas: gas.toString(),
      maxFeePerGas: maxFeePerGas.toString(),
      maxPriorityFeePerGas: maxPriorityFeePerGas.toString(),
    );

    return gsnTx;
  }

  Future<String> getClientId() async {
    // Replace this line with the actual method to get the bundleId from the native module
    final bundleId = await getBundleIdFromNativeModule();
//TODO:
    final hexValue = EthereumAddress.fromHex(bundleId).hex;
    return BigInt.parse(hexValue, radix: 16).toString();
  }

  Future<String> getBundleIdFromNativeModule() {
    // TODO: Replace this with the actual method to get the bundleId from the native module
    // Example: MethodChannel or Platform channel to communicate with native code
    // For demonstration purposes, we'll use a dummy value
    return Future.value('com.savez.app');
  }

  Future<String> handleGsnResponse(
    dynamic res,
    Web3Client ethClient,
  ) async {
    if (res.data['error'] != null) {
      throw {
        'message': 'RelayError',
        'details': res.data['error'],
      };
    } else {
      final txHash = keccak256(res.data['signedTx']).toString();
      // Poll for the transaction receipt until it's confirmed
      TransactionReceipt? receipt;
      do {
        receipt = await ethClient.getTransactionReceipt(txHash);
        if (receipt == null) {
          await Future.delayed(Duration(seconds: 2)); // Wait for 2 seconds
        }
      } while (receipt == null);
      return txHash;
    }
  }


class CalldataBytes {
  final int calldataZeroBytes;
  final int calldataNonzeroBytes;

  CalldataBytes(this.calldataZeroBytes, this.calldataNonzeroBytes);
}
