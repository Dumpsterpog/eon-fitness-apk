import 'dart:math';

import 'package:eon_fitness/state/account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final account = Account.create(
    name: '  Jin  ',
    email: '  Hunter@Example.COM ',
    password: 'arise123',
    random: Random(1),
    now: DateTime(2026, 11, 4),
  );

  test('normalises name and email', () {
    expect(account.name, 'Jin');
    expect(account.email, 'hunter@example.com');
  });

  test('never stores the password', () {
    expect(account.toJson().values.join(), isNot(contains('arise123')));
  });

  test('matches the right credentials only', () {
    expect(
      account.matches(email: 'HUNTER@example.com', password: 'arise123'),
      isTrue,
    );
    expect(
      account.matches(email: 'hunter@example.com', password: 'arise124'),
      isFalse,
    );
    expect(
      account.matches(email: 'other@example.com', password: 'arise123'),
      isFalse,
    );
  });

  test('salts differ, so equal passwords hash differently', () {
    final other = Account.create(
      name: 'B',
      email: 'b@b.co',
      password: 'arise123',
    );
    expect(other.salt, isNot(account.salt));
    expect(other.digest, isNot(account.digest));
  });

  test('survives a JSON round trip', () {
    final back = Account.tryParse(account.toJson())!;
    expect(
      back.matches(email: 'hunter@example.com', password: 'arise123'),
      isTrue,
    );
    expect(Account.tryParse({'name': 1}), isNull);
  });

  test('validation rules', () {
    expect(AccountRules.name(''), isNotNull);
    expect(AccountRules.name('Sung'), isNull);
    expect(AccountRules.email('nope'), isNotNull);
    expect(AccountRules.email('a@b.io'), isNull);
    expect(AccountRules.password('12345'), isNotNull);
    expect(AccountRules.password('123456'), isNull);
  });
}
