import 'package:sdk/gsnClient/gsnTxHelpers.dart';
import 'package:sdk/gsnClient/utils.dart';
import 'package:sdk/network.dart';
import 'package:sdk/utils/constants.dart';
import 'package:web3dart/web3dart.dart';

import '../account.dart';
import '../contracts/erc20.dart';
import '../error.dart';
import '../gsnClient/EIP712/MetaTransactions.dart';
import '../gsnClient/EIP712/PermitTransaction.dart';
import '../gsnClient/gsnClient.dart';
import '../network_config/network_config.dart';

class NetworkImpl extends Network{
  NetworkConfig network;

  NetworkImpl(this.network);

  @override
  Future<String> claimRly() async {
    final account = await AccountsUtil.getInstance().getWallet();

    if (account == null) {
      throw missingWalletError;
    }

    final existingBalance = await getBalance();
    // final existingBalance = 0;

    if (existingBalance > 0) {
      throw priorDustingError;
    }

    final ethers = getEthClient();

    final claimTx = await getClaimTx(account, network, ethers);
    //TODO: Fix this
    // final claimTx = null;

    return relay(claimTx);
  }

  @override
  Future<double> getBalance({PrefixedHexString? tokenAddress}) async {
    final account = await AccountsUtil.getInstance().getWallet();
    //if token address use it otherwise default to RLY
    tokenAddress = tokenAddress ?? network.contracts.rlyERC20;
    if (account == null) {
      throw missingWalletError;
    }

    final provider = getEthClientForURL(network.gsn.rpcUrl);
    //TODO: we have to use this provider to make this erc20 contract
    // final token = erc20(provider,tokenAddress);
    final token = erc20(tokenAddress);
    final funCall = await provider.call(contract: token, function: token.function("decimals"), params: []);
    final decimals = funCall[0];

    final balanceOfCall = await provider.call(contract: token, function: token.function('balanceOf'), params: [account.privateKey.address]);
    final balance = balanceOfCall[0];
    return formatUnits(balance, decimals);
  }

  @override
  Future<String> relay(GsnTransactionDetails tx) async {
    final account = await AccountsUtil.getInstance().getWallet();

    if (account == null) {
      throw missingWalletError;
    }

    return relayTransaction(account, network, tx);
  }

  @override
  void setApiKey(String apiKey) {
    network.relayerApiKey = apiKey;
  }

  double formatUnits(BigInt wei, BigInt decimals) {
    final etherUnit = EtherUnit.gwei;
    final balanceFormatted = EtherAmount.fromBigInt(etherUnit, wei)
        .getValueInUnit(EtherUnit.gwei);
    return balanceFormatted;
  }



  @override
  Future<String> transfer(String destinationAddress, double amount, {PrefixedHexString? tokenAddress, MetaTxMethod? metaTxMethod})
  async {
    final account = await AccountsUtil.getInstance().getWallet();

    tokenAddress = tokenAddress ?? network.contracts.rlyERC20;

    if (account == null) {
      throw missingWalletError;
    }

    final sourceBalance = await getBalance(tokenAddress: tokenAddress);

    final sourceFinalBalance = sourceBalance - amount;

    if (sourceFinalBalance < 0) {
      throw insufficientBalanceError;
    }

    final provider = getEthClientForURL(network.gsn.rpcUrl);

    GsnTransactionDetails? transferTx;

    if (metaTxMethod != null &&
        (metaTxMethod == MetaTxMethod.Permit ||
            metaTxMethod == MetaTxMethod.ExecuteMetaTransaction)) {
      if (metaTxMethod == MetaTxMethod.Permit) {
        transferTx = await getPermitTx(
          account,
          EthereumAddress.fromHex(destinationAddress),
          amount,
          network,
          tokenAddress,
          provider,
        );
      } else {
        transferTx = await getExecuteMetatransactionTx(
          account,
          destinationAddress,
          amount,
          network,
          tokenAddress,
          provider,
        );
      }
    } else {
      final executeMetaTransactionSupported = await hasExecuteMetaTransaction(
          account, destinationAddress, amount, network, tokenAddress, provider);

      final permitSupported = await hasPermit(
        account,
        amount,
        network,
        tokenAddress,
        provider,
      );

      if (executeMetaTransactionSupported) {
        transferTx = await getExecuteMetatransactionTx(
          account,
          destinationAddress,
          amount,
          network,
          tokenAddress,
          provider,
        );
      } else if (permitSupported) {
        transferTx = await getPermitTx(
          account,
          EthereumAddress.fromHex(destinationAddress),
          amount,
          network,
          tokenAddress,
          provider,
        );
      } else {
        throw transferMethodNotSupportedError;
      }
    }
    return relay(transferTx!);
  }

  // This method is deprecated. Update to 'claimRly' instead.
// Will be removed in future library versions.
  Future<String> registerAccount() async {
    print("This method is deprecated. Update to 'claimRly' instead.");
    return claimRly();
  }

  @override
  Future<String> simpleTransfer(String destinationAddress, double amount, {String? tokenAddress, MetaTxMethod? metaTxMethod}) async {
  Web3Client client = getEthClient();
  final account = await AccountsUtil.getInstance().getWallet();

  final result = await client.sendTransaction(
      EthPrivateKey.fromHex("f6125bb4f39bd9281eb6ee3f6f67f2f4d2694680b6996ff918341f720d8c1b26"),
    Transaction(
      to: EthereumAddress.fromHex('0x7829222A97392EFcBc743531222CB71606d6f2b4'),
      gasPrice: EtherAmount.fromInt(EtherUnit.gwei,1000),
      maxGas: 100000,
      value: EtherAmount.fromBigInt(EtherUnit.gwei, BigInt.from(3000000)),
    ),
    chainId: 80001
  );
  return result;
  }

}
