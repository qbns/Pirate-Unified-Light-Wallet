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

  group('TransactionErrorMapper.mapError', () {
    test('maps node broadcast rejection to txRejected, not networkError', () {
      // Mirrors the Rust error surfaced when a Sapling-only regtest node
      // refuses an NU5/v5 transaction: the inner message contains both
      // "network error" and "broadcast failed". The node-rejection branch must
      // win over the generic network fallback.
      final error = TransactionErrorMapper.mapError(
        'Broadcast failed on http://192.168.88.254:45467: '
        'Network error: Broadcast failed: tx-version-too-new (code -26)',
      );
      expect(error.type, TransactionErrorType.txRejected);
      expect(error.message, 'Transaction rejected by the node');
    });

    test('maps bad-txns consensus rejection to txRejected', () {
      final error = TransactionErrorMapper.mapError(
        'NON_RETRYABLE: Broadcast failed: bad-txns-sapling-binding-signature-invalid (code -26)',
      );
      expect(error.type, TransactionErrorType.txRejected);
    });

    test('still maps genuine connection failures to networkError', () {
      final error = TransactionErrorMapper.mapError(
        'Failed to connect to http://192.168.88.254:45467: '
        'Connection error: connection refused',
      );
      expect(error.type, TransactionErrorType.networkError);
    });
  });
}
