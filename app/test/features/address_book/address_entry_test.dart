import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_wallet/features/address_book/models/address_entry.dart';

void main() {
  group('AddressEntry.validate', () {
    const mainnetSapling = 'zs1v76p87z69sy895pggreps6y35z7v398sry05z8zsyppv89vsyqq69sy895pggreps6y35z7';
    const testnetSapling = 'ztestsapling1v76p87z69sy895pggreps6y35z7v398sry05z8zsyppv89vsyqq69sy895pggreps6y35z7v398sry05z8zsy';

    test('validates mainnet by default', () {
      final entry = AddressEntry.create(
        walletId: 'w1',
        address: mainnetSapling,
        label: 'Alice',
      );
      expect(entry.validate(), isEmpty);
    });

    test('validates testnet when specified', () {
      final entry = AddressEntry.create(
        walletId: 'w1',
        address: testnetSapling,
        label: 'Alice',
      );
      expect(entry.validate('testnet'), isEmpty);
    });

    test('fails testnet when mainnet specified', () {
      final entry = AddressEntry.create(
        walletId: 'w1',
        address: testnetSapling,
        label: 'Alice',
      );
      expect(entry.validate('mainnet'), isNotEmpty);
    });

    test('fails empty label', () {
      final entry = AddressEntry.create(
        walletId: 'w1',
        address: mainnetSapling,
        label: '',
      );
      expect(entry.validate(), contains('Label cannot be empty'));
    });
  });
}
