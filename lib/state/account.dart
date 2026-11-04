// Local, on-device account. Pure Dart (unit-tested on the Dart VM).
//
// This is showcase auth: there is no server, so the account only protects the
// profile on this phone. Passwords are still never stored — only a salted,
// iterated SHA-256 digest — so the stored data is safe to inspect.

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class Account {
  const Account({
    required this.name,
    required this.email,
    required this.salt,
    required this.digest,
    required this.createdAt,
  });

  /// Number of SHA-256 rounds. ~10 ms on a mid-range phone: slow enough to
  /// make brute-forcing a copied prefs file tedious, fast enough to feel
  /// instant on login.
  static const _rounds = 12000;

  final String name;
  final String email;
  final String salt;
  final String digest;
  final DateTime createdAt;

  static String normaliseEmail(String email) => email.trim().toLowerCase();

  factory Account.create({
    required String name,
    required String email,
    required String password,
    Random? random,
    DateTime? now,
  }) {
    final rnd = random ?? Random.secure();
    final saltBytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    final salt = base64UrlEncode(saltBytes);
    return Account(
      name: name.trim(),
      email: normaliseEmail(email),
      salt: salt,
      digest: _hash(salt, password),
      createdAt: now ?? DateTime.now(),
    );
  }

  bool matches({required String email, required String password}) =>
      normaliseEmail(email) == this.email &&
      _constantTimeEquals(_hash(salt, password), digest);

  Account rename(String newName) => Account(
    name: newName.trim(),
    email: email,
    salt: salt,
    digest: digest,
    createdAt: createdAt,
  );

  static String _hash(String salt, String password) {
    List<int> bytes = utf8.encode('$salt:$password');
    for (var i = 0; i < _rounds; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return base64UrlEncode(bytes);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  Map<String, Object?> toJson() => {
    'name': name,
    'email': email,
    'salt': salt,
    'digest': digest,
    'createdAt': createdAt.toIso8601String(),
  };

  static Account? tryParse(Map<String, Object?> j) {
    final name = j['name'];
    final email = j['email'];
    final salt = j['salt'];
    final digest = j['digest'];
    if (name is! String ||
        email is! String ||
        salt is! String ||
        digest is! String) {
      return null;
    }
    return Account(
      name: name,
      email: email,
      salt: salt,
      digest: digest,
      createdAt: DateTime.tryParse('${j['createdAt']}') ?? DateTime.now(),
    );
  }
}

/// Validation shared by the sign-up / login forms and the state layer.
abstract final class AccountRules {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? name(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Every hunter needs a name';
    if (s.length > 20) return 'Keep it under 20 characters';
    return null;
  }

  static String? email(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Enter your email';
    if (!_email.hasMatch(s)) return "That doesn't look like an email";
    return null;
  }

  static String? password(String? v) {
    final s = v ?? '';
    if (s.length < 6) return 'Use at least 6 characters';
    return null;
  }
}
