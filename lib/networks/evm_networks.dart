import 'package:sdk/gsnClient//utils.dart';
import 'package:sdk/utils/constants.dart';
import 'package:web3dart/web3dart.dart';

import '../account.dart';
import '../error.dart';
import '../network_config/network_config.dart';

import 'package:sdk/gsnClient/gsnClient.dart';
import 'package:sdk/gsnClient/gsnTxHelpers.dart';

Future<String> transfer(
  String destinationAddress,
  double amount,
  NetworkConfig network, {
  PrefixedHexString? tokenAddress,
  MetaTxMethod? metaTxMethod,
}) async {
  final account = await AccountsUtil.getInstance().getWallet();

  tokenAddress = tokenAddress ?? network.contracts.rlyERC20;

  if (account == null) {
    throw missingWalletError;
  }

  final sourceBalance = await getBalance(network, tokenAddress: tokenAddress);

  final sourceFinalBalance = sourceBalance - amount;

  if (sourceFinalBalance < 0) {
    throw insufficientBalanceError;
  }

  final ethers = getEthClient();

  Transaction? transferTx;

  if (metaTxMethod != null &&
      (metaTxMethod == MetaTxMethod.Permit || metaTxMethod == MetaTxMethod.e)) {
    if (metaTxMethod == MetaTxMethod.Permit) {
      transferTx = await getPermitTx(
        account,
        destinationAddress,
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
        destinationAddress,
        amount,
        network,
        tokenAddress,
        ethers,
      );
    } else {
      throw TransferMethodNotSupportedError();
    }
  }
  return relay(transferTx!, network);
}

Future<double> getBalance(
  NetworkConfig network, {
  PrefixedHexString? tokenAddress,
}) async {
  final account = await AccountsUtil.getInstance().getWallet();

  //if token address use it otherwise default to RLY
  tokenAddress = tokenAddress ?? network.contracts.rlyERC20;
  if (account == null) {
    throw missingWalletError;
  }

  final ethers = getEthClient();

  final token = erc20(ethers, tokenAddress);
  final decimals = await token.decimals();
  final bal = await token.balanceOf(account.address);
  return double.parse(ethers.utils.formatUnits(bal.toString(), decimals));
}

Future<String> claimRly(NetworkConfig network) async {
  final account = await AccountsUtil.getInstance().getWallet();

  if (account == null) {
    throw missingWalletError;
  }

  final existingBalance = await getBalance(network);

  if (existingBalance > 0) {
    throw priorDustingError;
  }

  final ethers = getEthClient();

  final claimTx = await getClaimTx(account, network, ethers);

  return relay(claimTx, network);
}

// This method is deprecated. Update to 'claimRly' instead.
// Will be removed in future library versions.
Future<String> registerAccount(NetworkConfig network) async {
  print("This method is deprecated. Update to 'claimRly' instead.");

  return claimRly(network);
}

Future<String> relay(
  GsnTransactionDetails tx,
  NetworkConfig network,
) async {
  final account = await AccountsUtil.getInstance().getWallet();

  if (account == null) {
    throw missingWalletError;
  }

  return relayTransaction(account, network, tx);
}

dynamic getEvmNetwork(NetworkConfig network) {
  return {
    'transfer': (
      String destinationAddress,
      double amount, {
      PrefixedHexString? tokenAddress,
      MetaTxMethod? metaTxMethod,
    }) {
      return transfer(
        destinationAddress,
        amount,
        network,
        tokenAddress: tokenAddress,
        metaTxMethod: metaTxMethod,
      );
    },
    'getBalance': (PrefixedHexString? tokenAddress) {
      return getBalance(network, tokenAddress: tokenAddress);
    },
    'claimRly': () {
      return claimRly(network);
    },
    // This method is deprecated. Update to 'claimRly' instead.
    // Will be removed in future library versions.
    'registerAccount': () {
      return registerAccount(network);
    },
    'relay': (GsnTransactionDetails tx) {
      return relay(tx, network);
    },
    'setApiKey': (String apiKey) {
      network.relayerApiKey = apiKey;
    },
  };
}
