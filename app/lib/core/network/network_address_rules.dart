/// Network-aware Pirate Chain address rules.
///
/// This is the single source of truth for the address prefixes, length
/// constraints, user-facing hints, and human-readable prefix descriptions used
/// across validation, error mapping, and UI placeholders.
library;

/// Supported Pirate Chain network types.
enum PirateNetwork {
  mainnet,
  testnet,
  regtest;

  /// Resolve a [PirateNetwork] from a raw network type string.
  ///
  /// Unknown or `null` values fall back to [PirateNetwork.mainnet].
  static PirateNetwork fromString(String? networkType) {
    switch (networkType?.toLowerCase()) {
      case 'testnet':
        return PirateNetwork.testnet;
      case 'regtest':
        return PirateNetwork.regtest;
      default:
        return PirateNetwork.mainnet;
    }
  }
}

/// Address format rules for a specific [PirateNetwork].
///
/// Centralizes the shielded (Sapling) and Orchard address prefixes together
/// with their acceptable length ranges so validation, error messages, and UI
/// hints all stay consistent.
class NetworkAddressRules {
  const NetworkAddressRules({
    required this.network,
    required this.saplingPrefix,
    required this.orchardPrefix,
    required this.minLength,
    required this.saplingMaxLength,
    required this.orchardMaxLength,
  });

  final PirateNetwork network;
  final String saplingPrefix;
  final String orchardPrefix;
  final int minLength;
  final int saplingMaxLength;
  final int orchardMaxLength;

  static const NetworkAddressRules mainnet = NetworkAddressRules(
    network: PirateNetwork.mainnet,
    saplingPrefix: 'zs1',
    orchardPrefix: 'pirate1',
    minLength: 70,
    saplingMaxLength: 110,
    orchardMaxLength: 140,
  );

  static const NetworkAddressRules testnet = NetworkAddressRules(
    network: PirateNetwork.testnet,
    saplingPrefix: 'ztestsapling1',
    orchardPrefix: 'pirate-test1',
    minLength: 80,
    saplingMaxLength: 200,
    orchardMaxLength: 250,
  );

  static const NetworkAddressRules regtest = NetworkAddressRules(
    network: PirateNetwork.regtest,
    saplingPrefix: 'zregtestsapling1',
    orchardPrefix: 'pirate-regtest1',
    minLength: 80,
    saplingMaxLength: 200,
    orchardMaxLength: 250,
  );

  /// Resolve the rules for the given [network].
  factory NetworkAddressRules.of(PirateNetwork network) {
    switch (network) {
      case PirateNetwork.testnet:
        return testnet;
      case PirateNetwork.regtest:
        return regtest;
      case PirateNetwork.mainnet:
        return mainnet;
    }
  }

  /// Resolve the rules for a raw [networkType] string (e.g. from wallet
  /// metadata). Unknown values fall back to [mainnet].
  factory NetworkAddressRules.forNetworkType(String? networkType) =>
      NetworkAddressRules.of(PirateNetwork.fromString(networkType));

  /// Whether [address] is a Sapling (shielded) address for this network.
  bool isSapling(String address) =>
      address.toLowerCase().startsWith(saplingPrefix);

  /// Whether [address] is an Orchard address for this network.
  bool isOrchard(String address) =>
      address.toLowerCase().startsWith(orchardPrefix);

  /// Whether [address] starts with a recognized prefix for this network.
  bool hasValidPrefix(String address) =>
      isSapling(address) || isOrchard(address);

  /// Whether [length] is within the acceptable range for the address type.
  bool isValidLength(int length, {required bool orchard}) {
    final maxLength = orchard ? orchardMaxLength : saplingMaxLength;
    return length >= minLength && length <= maxLength;
  }

  /// Human-readable list of accepted prefixes, e.g. `"zs1" or "pirate1"`.
  String get expectedPrefixes => '"$saplingPrefix" or "$orchardPrefix"';

  /// Placeholder hint for address input fields, e.g. `zs1...`.
  String get inputHint => '$saplingPrefix...';
}
