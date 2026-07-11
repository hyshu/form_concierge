import 'dart:convert';
import 'dart:io';

import 'cli_exception.dart';

Future<bool> commandExists(String command) async {
  try {
    final result = Platform.isWindows
        ? await Process.run('where', [command], runInShell: true)
        : await Process.run('sh', ['-c', r'command -v -- "$1"', '_', command]);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

/// Runs a process with inherited stdio. Throws [CliException] on non-zero exit.
Future<void> runInherit(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    mode: ProcessStartMode.inheritStdio,
    runInShell: Platform.isWindows,
  );
  final code = await process.exitCode;
  if (code != 0) {
    throw CliException(
      'Command failed (exit $code): $executable ${arguments.join(' ')}',
      exitCode: code,
    );
  }
}

/// Runs a process and captures stdout/stderr.
Future<ProcessResult> runCapture(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool throwOnError = true,
}) async {
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    runInShell: Platform.isWindows,
  );
  if (throwOnError && result.exitCode != 0) {
    final err = (result.stderr as String).trim();
    final out = (result.stdout as String).trim();
    final detail = [
      if (out.isNotEmpty) out,
      if (err.isNotEmpty) err,
    ].join('\n');
    throw CliException(
      'Command failed (exit ${result.exitCode}): '
      '$executable ${arguments.join(' ')}\n$detail',
      exitCode: result.exitCode,
    );
  }
  return result;
}

/// Like [runInherit] but returns the captured combined stream as a string
/// while also writing it to stderr (similar to `tee`).
Future<({int exitCode, String output})> runTee(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    runInShell: Platform.isWindows,
  );
  final buffer = StringBuffer();
  final outDone = process.stdout.transform(utf8.decoder).listen((chunk) {
    buffer.write(chunk);
    stderr.write(chunk);
  }).asFuture<void>();
  final errDone = process.stderr.transform(utf8.decoder).listen((chunk) {
    buffer.write(chunk);
    stderr.write(chunk);
  }).asFuture<void>();
  final code = await process.exitCode;
  await Future.wait([outDone, errDone]);
  return (exitCode: code, output: buffer.toString());
}

Future<String> promptName(String label, String defaultValue) async {
  if (!stdin.hasTerminal) {
    return '';
  }
  stderr.write('$label \x1b[2m$defaultValue\x1b[0m ');
  final answer = stdin.readLineSync();
  if (answer == null || answer.trim().isEmpty) {
    return defaultValue;
  }
  return answer.trim();
}

Future<String?> promptOptional(String message) async {
  if (!stdin.hasTerminal) {
    return null;
  }
  stderr.write(message);
  return stdin.readLineSync();
}
