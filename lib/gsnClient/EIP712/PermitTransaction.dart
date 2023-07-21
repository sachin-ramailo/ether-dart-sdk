import 'package:web3dart/web3dart.dart';
import 'package:meta/meta.dart';

import '../../network_config/network_config.dart';

class Permit {
  String name;
  String version;
  String chainId;
  String verifyingContract;
  String owner;
  String spender;
  dynamic value;
  dynamic nonce;
  dynamic deadline;
  String salt;

  Permit({
    required this.name,
    required this.version,
    required this.chainId,
    required this.verifyingContract,
    required this.owner,
    required this.spender,
    required this.value,
    required this.nonce,
    required this.deadline,
    required this.salt,
  });
}

Map<String, dynamic> getTypedPermitTransaction(Permit permit) {
  return {
    'types': {
      'Permit': [
        {'name': 'owner', 'type': 'address'},
        {'name': 'spender', 'type': 'address'},
        {'name': 'value', 'type': 'uint256'},
        {'name': 'nonce', 'type': 'uint256'},
        {'name': 'deadline', 'type': 'uint256'},
      ],
    },
    'primaryType': 'Permit',
    'domain': {
      'name': permit.name,
      'version': permit.version,
      'chainId': permit.chainId,
      'verifyingContract': permit.verifyingContract,
      if (permit.salt != '0x' && permit.salt.isNotEmpty) 'salt': permit.salt,
    },
    'message': {
      'owner': permit.owner,
      'spender': permit.spender,
      'value': permit.value.toString(),
      'nonce': permit.nonce.toString(),
      'deadline': permit.deadline.toString(),
    },
  };
}

Future<Map<String, dynamic>> getPermitEIP712Signature(
  Wallet account,
  String contractName,
  String contractAddress,
  NetworkConfig config,
  int nonce,
  BigInt amount,
  int deadline,
  String salt,
) async {
  // chainId to be used in EIP712
  final chainId = config.gsn.chainId;

  // typed data for signing
  final eip712Data = getTypedPermitTransaction(
    Permit(
      name: contractName,
      version: '1',
      chainId: chainId,
      verifyingContract: contractAddress,
      owner: account.privateKey.address.hex,
      spender: config.gsn.paymasterAddress,
      value: amount.toString(),
      nonce: nonce.toString(),
      deadline: deadline.toString(),
      salt: salt,
    ),
  );

  // signature for metatransaction
  final signature = await account.signTypedData(
    eip712Data['domain'],
    eip712Data['types'],
    eip712Data['message'],
  );

  // get r, s, v from signature
  final splitSignature = account.splitSignature(signature);

  return {
    'r': splitSignature.r,
    's': splitSignature.s,
    'v': splitSignature.v,
  };
}

Future<bool> hasPermit(
  Wallet account,
  int amount,
  NetworkConfig config,
  String contractAddress,
  Web3Client provider,
) async {
  try {
    final token = erc20(provider, EthereumAddress.fromHex(contractAddress));

    final name = await token.name();
    final nonce = await token
        .nonces(EthereumAddress.fromHex(account.privateKey.address.hex));
    final decimals = await token.decimals();
    final deadline = await getPermitDeadline(provider);
    final eip712Domain = await token.eip712Domain();

    final salt = eip712Domain['salt'] as String;

    final decimalAmount = EtherAmount.fromInt(EtherUnit.ether, amount);

    final signature = await getPermitEIP712Signature(
      account,
      name,
      contractAddress,
      config,
      nonce.toInt(),
      decimalAmount.getInWei,
      deadline,
      salt,
    );

    await token.estimateGas(
      'permit',
      [
        EthereumAddress.fromHex(account.privateKey.address.hex),
        EthereumAddress.fromHex(config.gsn.paymasterAddress),
        decimalAmount.getInWei,
        deadline,
        signature['v'],
        signature['r'],
        signature['s'],
      ],
      from: EthereumAddress.fromHex(account.privateKey.address.hex),
    );

    return true;
  } catch (e) {
    return false;
  }
}

Future<Map<String, dynamic>> getPermitTx(
  Wallet account,
  EthereumAddress destinationAddress,
  int amount,
  NetworkConfig config,
  String contractAddress,
  Web3Client provider,
) async {
  final token = erc20(provider, EthereumAddress.fromHex(contractAddress));

  final name = await token.name();
  final nonce = await token
      .nonces(EthereumAddress.fromHex(account.privateKey.address.hex));
  final decimals = await token.decimals();
  final deadline = await getPermitDeadline(provider);
  final eip712Domain = await token.eip712Domain();

  final salt = eip712Domain['salt'] as String;

  final decimalAmount = EtherAmount.fromInt(EtherUnit.ether, amount);

  final signature = await getPermitEIP712Signature(
    account,
    name,
    contractAddress,
    config,
    nonce.toInt(),
    decimalAmount.getInWei,
    deadline,
    salt,
  );

  final tx = await token.estimateGas(
    'permit',
    [
      EthereumAddress.fromHex(account.privateKey.address.hex),
      EthereumAddress.fromHex(config.gsn.paymasterAddress),
      decimalAmount.getInWei,
      deadline,
      signature['v'],
      signature['r'],
      signature['s'],
    ],
    from: EthereumAddress.fromHex(account.privateKey.address.hex),
  );

  final fromTx = await token.estimateGas(
    'transferFrom',
    [
      EthereumAddress.fromHex(account.privateKey.address.hex),
      destinationAddress,
      decimalAmount.getInWei,
    ],
    from: EthereumAddress.fromHex(account.privateKey.address.hex),
  );

  final paymasterData = '0x' +
      token.address.hex.replaceFirst('0x', '') +
      fromTx.data.replaceFirst('0x', '');

  final feeData = await provider.getFeeData();
  final maxFeePerGas = feeData['maxFeePerGas'];
  final maxPriorityFeePerGas = feeData['maxPriorityFeePerGas'];

  final gsnTx = {
    'from': account.privateKey.address.hex,
    'data': tx.data,
    'value': '0',
    'to': tx.to.hex,
    'gas': tx.gasPrice.getInWei,
    'maxFeePerGas': maxFeePerGas.getInWei,
    'maxPriorityFeePerGas': maxPriorityFeePerGas.getInWei,
    'paymasterData': paymasterData,
  };

  return gsnTx;
}

// get timestamp that will always be included in the next 3 blocks
Future<int> getPermitDeadline(Web3Client provider) async {
  final block = await provider.getBlock('latest');
  return block.timestamp + 45;
}
