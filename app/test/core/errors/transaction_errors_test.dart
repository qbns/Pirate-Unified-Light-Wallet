import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_wallet/core/errors/transaction_errors.dart';

void main() {
  group('TransactionErrorMapper.validateAddress', () {
    const mainnetSapling = 'zs1v76p87z69sy895pggreps6y35z7v398sry05z8zsyppv89vsyqq69sy895pggreps6y35z7'; // ~78 chars
    const mainnetOrchard = 'pirate1v76p87z69sy895pggreps6y35z7v398sry05z8zsyppv89vsyqq69sy895pggreps6y35z7v398sry05z8zsy'; // ~90 chars
    const testnetSapling = 'ztestsapling1v76p87z69sy895pggreps6y35z7v398sry05z8zsyppv89vsyqq69sy895pggreps6y35z7v398sry05z8zsy'; // ~100 chars
    const testnetOrchard = 'pirate-test1v76p87z69sy895pggreps6y35z7v398sry05z8zsyppv89vsyqq69sy895pggreps6y35z7v398sry05z8zsy'; // ~100 chars
    const regtestSapling = 'zregtestsapling1v76p87z69sy895pggreps6y35z7v398sry05z8zsyppv89vsyqq69sy895pggreps6y35z7v398sry05z8zsyppv89vsyqq69sy895pggreps6y35z7v398sry05z8zsyppv89vsyqq69sy895pggreps6y35z7'; // ~160 chars
    const regtestOrchard = 'pirate-regtest1v76p87z69sy895pggreps6y35z7v398sry05z8zsyppv89vsyqq69sy895pggreps6y35z7v398sry05z8zsyppv89vsyqq69sy895pggreps6y35z7v398sry05z8zsyppv89vsyqq69sy895pggreps6y35z7'; // ~160 chars

    test('validates mainnet addresses by default', () {
      expect(TransactionErrorMapper.validateAddress(mainnetSapling), isNull);
      expect(TransactionErrorMapper.validateAddress(mainnetOrchard), isNull);
      expect(TransactionErrorMapper.validateAddress(testnetSapling), isNotNull);
    });

    test('validates mainnet addresses explicitly', () {
      expect(TransactionErrorMapper.validateAddress(mainnetSapling, 'mainnet'), isNull);
      expect(TransactionErrorMapper.validateAddress(mainnetOrchard, 'mainnet'), isNull);
      expect(TransactionErrorMapper.validateAddress(testnetSapling, 'mainnet'), isNotNull);
    });

    test('validates testnet addresses', () {
      expect(TransactionErrorMapper.validateAddress(testnetSapling, 'testnet'), isNull);
      expect(TransactionErrorMapper.validateAddress(testnetOrchard, 'testnet'), isNull);
      expect(TransactionErrorMapper.validateAddress(mainnetSapling, 'testnet'), isNotNull);
    });

    test('validates regtest addresses', () {
      expect(TransactionErrorMapper.validateAddress(regtestSapling, 'regtest'), isNull);
      expect(TransactionErrorMapper.validateAddress(regtestOrchard, 'regtest'), isNull);
      expect(TransactionErrorMapper.validateAddress(mainnetSapling, 'regtest'), isNotNull);
    });

    test('returns error for empty address', () {
      final error = TransactionErrorMapper.validateAddress('');
      expect(error, isNotNull);
      expect(error!.type, TransactionErrorType.invalidAddress);
    });
  });
}
