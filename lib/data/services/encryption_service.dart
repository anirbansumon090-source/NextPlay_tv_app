// lib/data/services/encryption_service.dart

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

import '../../core/constants/app_constants.dart';

class EncryptionService {
  EncryptionService({String? secretKey})
      : _key = Key.fromUtf8(secretKey ?? AppConstants.encryptionKey),
        _ivLength = 12;

  final Key _key;
  final int _ivLength;

  /// Encrypts [plainText] with AES-256-GCM and returns a dot-separated
  /// base64 string: `<iv>.<ciphertext>`.
  String encrypt(String plainText) {
    final iv = IV.fromSecureRandom(_ivLength);
    final encrypter = Encrypter(AES(_key, mode: AESMode.gcm));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${base64Encode(iv.bytes)}.${encrypted.base64}';
  }

  /// Decrypts a payload previously produced by [encrypt].
  String decrypt(String payload) {
    final parts = payload.split('.');
    if (parts.length != 2) {
      throw const FormatException('Encrypted payload format is invalid');
    }

    final iv = IV(base64Decode(parts.first));
    final encrypter = Encrypter(AES(_key, mode: AESMode.gcm));
    final encrypted = Encrypted.fromBase64(parts.last);
    return encrypter.decrypt(encrypted, iv: iv);
  }

  /// Returns an HMAC-SHA256 hex digest over [payload].
  String sign(String payload, {String? secret}) {
    final key = utf8.encode(secret ?? AppConstants.hmacSecret);
    final bytes = utf8.encode(payload);
    return Hmac(sha256, key).convert(bytes).toString();
  }

  /// Returns true when [signature] matches [sign(payload)].
  bool verify(String payload, String signature, {String? secret}) {
    return sign(payload, secret: secret) == signature;
  }
}
