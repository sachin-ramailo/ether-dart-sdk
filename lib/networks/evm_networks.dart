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

    if (existingBalance > 0) {
      throw priorDustingError;
    }

    final ethers = getEthClient();

    // final claimTx = await getClaimTx(account, network, ethers);
    //TODO: Fix this
    final claimTx = null;

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
    // final decimals = await token.decimals();
    //TODO: we have to use this token to get balance of this erc20 contract
    final bal = await provider.getBalance(account.privateKey.address);
    return bal.getValueInUnit(EtherUnit.gwei);
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

    final ethers = getEthClient();

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
          ethers,
        );
      } else {
        transferTx = await getExecuteMetatransactionTx(
          account,
          destinationAddress,
          amount,
          network,
          tokenAddress,
          ethers,
        );
      }
    } else {
      final executeMetaTransactionSupported = await hasExecuteMetaTransaction(
          account, destinationAddress, amount, network, tokenAddress, ethers);

      final permitSupported = await hasPermit(
        account,
        amount,
        network,
        tokenAddress,
        ethers,
      );

      if (executeMetaTransactionSupported) {
        transferTx = await getExecuteMetatransactionTx(
          account,
          destinationAddress,
          amount,
          network,
          tokenAddress,
          ethers,
        );
      } else if (permitSupported) {
        transferTx = await getPermitTx(
          account,
          EthereumAddress.fromHex(destinationAddress),
          amount,
          network,
          tokenAddress,
          ethers,
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

}
