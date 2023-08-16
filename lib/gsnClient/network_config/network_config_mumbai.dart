import '../../network_config/network_config.dart';

class NetworkConfig {
  final Contracts contracts;
  final GSNConfig gsn;

  NetworkConfig({required this.contracts, required this.gsn});
}

// MumbaiNetworkConfig
final mumbaiNetworkConfig = NetworkConfig(
  contracts: Contracts(
    tokenFaucet: '0xe7C3BD692C77Ec0C0bde523455B9D142c49720fF',
    rlyERC20: '0x1C7312Cb60b40cF586e796FEdD60Cf243286c9E9',
  ),
  gsn: GSNConfig(
    paymasterAddress: '0x499D418D4493BbE0D9A8AF3D2A0768191fE69B87',
    forwarderAddress: '0xB2b5841DBeF766d4b521221732F9B618fCf34A87',
    relayHubAddress: '0x3232f21A6E08312654270c78A773f00dd61d60f5',
    relayWorkerAddress: '0x7b556ef275185122257090bd59f74fe4c3c3ca96',
    relayUrl: 'https://api.rallyprotocol.com',
    rpcUrl:
        'https://polygon-mumbai.infura.io/v3/fc4ab81f4b824f9e9c3bdd065f765afc',
    chainId: '80001',
    maxAcceptanceBudget: '285252',
    domainSeparatorName: 'GSN Relayed Transaction',
    gtxDataNonZero: 16,
    gtxDataZero: 4,
    requestValidSeconds: 172800,
    maxPaymasterDataLength: 300,
    maxApprovalDataLength: 300,
    maxRelayNonceGap: 3,
  ),
);
