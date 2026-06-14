import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_wallet/core/network/network_address_rules.dart';

void main() {
  group('PirateNetwork.fromString', () {
    test('maps known network types', () {
      expect(PirateNetwork.fromString('mainnet'), PirateNetwork.mainnet);
      expect(PirateNetwork.fromString('testnet'), PirateNetwork.testnet);
      expect(PirateNetwork.fromString('regtest'), PirateNetwork.regtest);
    });

    test('is case-insensitive', () {
      expect(PirateNetwork.fromString('TESTNET'), PirateNetwork.testnet);
    });

    test('falls back to mainnet for null/unknown', () {
      expect(PirateNetwork.fromString(null), PirateNetwork.mainnet);
      expect(PirateNetwork.fromString('bogus'), PirateNetwork.mainnet);
    });
  });

  group('NetworkAddressRules.forNetworkType', () {
    test('returns the matching rules', () {
      expect(
        NetworkAddressRules.forNetworkType('testnet').network,
        PirateNetwork.testnet,
      );
      expect(
        NetworkAddressRules.forNetworkType(null).network,
        PirateNetwork.mainnet,
      );
    });
  });

  group('prefix detection', () {
    test('mainnet recognizes its prefixes', () {
      const rules = NetworkAddressRules.mainnet;
      expect(rules.isSapling('zs1abc'), isTrue);
      expect(rules.isOrchard('pirate1abc'), isTrue);
      expect(rules.hasValidPrefix('ztestsapling1abc'), isFalse);
    });

    test('testnet recognizes its prefixes', () {
      const rules = NetworkAddressRules.testnet;
      expect(rules.isSapling('ztestsapling1abc'), isTrue);
      expect(rules.isOrchard('pirate-test1abc'), isTrue);
      expect(rules.hasValidPrefix('zs1abc'), isFalse);
    });
  });

  group('helpers', () {
    test('expectedPrefixes and inputHint are network-specific', () {
      expect(
        NetworkAddressRules.mainnet.expectedPrefixes,
        '"zs1" or "pirate1"',
      );
      expect(NetworkAddressRules.mainnet.inputHint, 'zs1...');
      expect(
        NetworkAddressRules.testnet.inputHint,
        'ztestsapling1...',
      );
    });

    test('isValidLength respects address type bounds', () {
      const rules = NetworkAddressRules.mainnet;
      expect(rules.isValidLength(80, orchard: false), isTrue);
      expect(rules.isValidLength(10, orchard: false), isFalse);
      expect(rules.isValidLength(130, orchard: true), isTrue);
      expect(rules.isValidLength(130, orchard: false), isFalse);
    });
  });
}
