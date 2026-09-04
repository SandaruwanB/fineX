import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finex/features/accounts/accounts_provider.dart';

void main() {
  group('Account Model & Default Status Tests', () {
    test('Account serialization and deserialization with isDefault flag', () {
      final account = Account(
        id: 'acc_001',
        name: 'Primary Vault',
        balance: 25000.50,
        type: 'savings',
        color: const Color(0xFF3B82F6),
        isDefault: true,
      );

      final map = account.toMap();
      expect(map['id'], 'acc_001');
      expect(map['name'], 'Primary Vault');
      expect(map['balance'], 25000.50);
      expect(map['type'], 'savings');
      expect(map['is_default'], 1);

      final roundtrip = Account.fromMap(map);
      expect(roundtrip.id, 'acc_001');
      expect(roundtrip.name, 'Primary Vault');
      expect(roundtrip.balance, 25000.50);
      expect(roundtrip.type, 'savings');
      expect(roundtrip.isDefault, true);
    });

    test('Account copyWith correctly updates isDefault state', () {
      final account = Account(
        id: 'acc_002',
        name: 'Secondary Checking',
        balance: 1500.0,
        type: 'checking',
        color: const Color(0xFF10B981),
        isDefault: false,
      );

      final updated = account.copyWith(isDefault: true);
      expect(updated.isDefault, true);
      expect(updated.id, 'acc_002');
      expect(updated.balance, 1500.0);

      final downgraded = updated.copyWith(isDefault: false);
      expect(downgraded.isDefault, false);
    });
  });
}
