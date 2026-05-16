import 'dart:convert';
import 'dart:developer' as dev;

import '../env/app_env.dart';

class ApiLogger {
  ApiLogger._();

  static const _name = 'API';

  static void logRequest({
    required String method,
    required String url,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) {
    if (!AppEnv.isDev) return;

    final buf = StringBuffer()
      ..writeln('┌─ REQUEST ──────────────────────────────────────')
      ..writeln('│  $method  $url')
      ..writeln('│  Headers:');

    headers.forEach((k, v) {
      final display = k == 'Authorization' ? 'Bearer [masked]' : v;
      buf.writeln('│    $k: $display');
    });

    if (body != null) {
      buf
        ..writeln('│  Body:')
        ..writeln(_indent(_prettyJson(body)));
    }

    buf.write('└────────────────────────────────────────────────');
    dev.log(buf.toString(), name: _name);
  }

  static void logResponse({
    required int statusCode,
    required String url,
    required String rawBody,
  }) {
    if (!AppEnv.isDev) return;

    final ok = statusCode >= 200 && statusCode < 300;
    final buf = StringBuffer()
      ..writeln('┌─ RESPONSE ─────────────────────────────────────')
      ..writeln('│  ${ok ? '✓' : '✗'}  $statusCode  $url')
      ..writeln('│  Body:')
      ..writeln(_indent(_tryPrettyJson(rawBody)))
      ..write('└────────────────────────────────────────────────');

    dev.log(buf.toString(), name: _name);
  }

  static void logRefresh({required bool success}) {
    if (!AppEnv.isDev) return;
    dev.log(
      'Token refresh ${success ? '✓ succeeded' : '✗ failed'}',
      name: _name,
    );
  }

  static void logError({required String url, required Object error}) {
    if (!AppEnv.isDev) return;
    dev.log(
      '┌─ ERROR ────────────────────────────────────────\n'
      '│  $url\n'
      '│  $error\n'
      '└────────────────────────────────────────────────',
      name: _name,
      error: error,
    );
  }

  static String _indent(String text) =>
      text.split('\n').map((l) => '│    $l').join('\n');

  static String _prettyJson(Map<String, dynamic> json) {
    const enc = JsonEncoder.withIndent('  ');
    return enc.convert(json);
  }

  static String _tryPrettyJson(String raw) {
    try {
      const enc = JsonEncoder.withIndent('  ');
      return enc.convert(jsonDecode(raw));
    } catch (_) {
      return raw;
    }
  }
}
