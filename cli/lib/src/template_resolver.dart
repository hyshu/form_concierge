import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'cli_exception.dart';

const formConciergeCliVersion = '0.1.1';
const _githubRepository = 'hyshu/form_concierge';
const _maximumTemplateBytes = 250 * 1024 * 1024;

typedef TemplateDownloader = Future<List<int>> Function(Uri uri);

/// Resolves a versioned Form Concierge release template into a local cache.
class TemplateResolver {
  TemplateResolver({
    String? cacheRoot,
    TemplateDownloader? downloader,
    void Function(String message)? log,
  }) : cacheRoot = cacheRoot ?? defaultTemplateCacheRoot(),
       _downloader = downloader ?? _download,
       _log = log ?? stderr.writeln;

  final String cacheRoot;
  final TemplateDownloader _downloader;
  final void Function(String message) _log;

  /// Returns a monorepo-compatible template root.
  Future<String> resolve({
    String version = formConciergeCliVersion,
    String? archiveUrl,
    String? expectedSha256,
    bool offline = false,
    bool refresh = false,
  }) async {
    _validateVersion(version);
    final destination = p.join(cacheRoot, version);

    if (!refresh && _isTemplateRoot(destination)) {
      _log('Using cached Form Concierge template $version: $destination');
      return destination;
    }
    if (offline) {
      throw CliException(
        'Template $version is not available in the local cache: $destination\n'
        'Run again without --offline to download it.',
      );
    }

    final assetUri = archiveUrl == null
        ? defaultTemplateArchiveUri(version)
        : _parseHttpUri(archiveUrl, '--template-url');
    final checksum = expectedSha256 == null
        ? await _downloadChecksum(Uri.parse('$assetUri.sha256'))
        : _normalizeChecksum(expectedSha256, '--template-sha256');

    _log('Downloading Form Concierge template $version from $assetUri');
    final archiveBytes = await _downloader(assetUri);
    if (archiveBytes.length > _maximumTemplateBytes) {
      throw CliException(
        'Template archive is too large (${archiveBytes.length} bytes; '
        'maximum $_maximumTemplateBytes).',
      );
    }
    final actualChecksum = sha256.convert(archiveBytes).toString();
    if (actualChecksum != checksum) {
      throw CliException(
        'Template checksum mismatch.\nExpected: $checksum\nActual:   $actualChecksum',
      );
    }

    final parent = Directory(cacheRoot)..createSync(recursive: true);
    final temporary = Directory(
      p.join(parent.path, '.$version-${DateTime.now().microsecondsSinceEpoch}'),
    );
    temporary.createSync();
    try {
      _extractTarGz(archiveBytes, temporary.path);
      if (!_isTemplateRoot(temporary.path)) {
        throw CliException(
          'Downloaded template is missing required Form Concierge files.',
        );
      }
      final existing = Directory(destination);
      if (existing.existsSync()) existing.deleteSync(recursive: true);
      temporary.renameSync(destination);
    } on CliException {
      rethrow;
    } on Object catch (error) {
      throw CliException('Could not extract Form Concierge template: $error');
    } finally {
      if (temporary.existsSync()) temporary.deleteSync(recursive: true);
    }

    _log('Cached Form Concierge template $version: $destination');
    return destination;
  }

  Future<String> _downloadChecksum(Uri uri) async {
    _log('Downloading template checksum from $uri');
    final bytes = await _downloader(uri);
    return _normalizeChecksum(String.fromCharCodes(bytes), uri.toString());
  }

  static Future<List<int>> _download(Uri uri) async {
    try {
      final response = await http.get(uri);
      if (response.statusCode != HttpStatus.ok) {
        throw CliException(
          'Template download failed (${response.statusCode}): $uri',
        );
      }
      return response.bodyBytes;
    } on CliException {
      rethrow;
    } on Object catch (error) {
      throw CliException('Template download failed: $uri\n$error');
    }
  }
}

Uri defaultTemplateArchiveUri(String version) => Uri.https(
  'github.com',
  '/$_githubRepository/releases/download/v$version/'
      'form-concierge-template-$version.tar.gz',
);

String defaultTemplateCacheRoot() {
  if (Platform.isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null && localAppData.isNotEmpty) {
      return p.join(localAppData, 'FormConcierge', 'templates');
    }
  }
  final xdg = Platform.environment['XDG_CACHE_HOME'];
  if (xdg != null && xdg.isNotEmpty) {
    return p.join(xdg, 'form_concierge', 'templates');
  }
  final home =
      Platform.environment[Platform.isWindows ? 'USERPROFILE' : 'HOME'];
  if (home == null || home.isEmpty) {
    return p.join(Directory.systemTemp.path, 'form_concierge', 'templates');
  }
  return p.join(home, '.cache', 'form_concierge', 'templates');
}

void _extractTarGz(List<int> bytes, String outputRoot) {
  final tarBytes = const GZipDecoder().decodeBytes(bytes, verify: true);
  final archive = TarDecoder().decodeBytes(tarBytes, verify: true);
  final root = p.canonicalize(outputRoot);

  for (final entry in archive) {
    if (entry.isSymbolicLink) {
      throw CliException(
        'Template archive contains a symbolic link: ${entry.name}',
      );
    }
    final normalized = p.posix.normalize(entry.name);
    if (normalized == '.' || normalized.isEmpty) continue;
    if (p.posix.isAbsolute(normalized) ||
        normalized == '..' ||
        normalized.startsWith('../')) {
      throw CliException(
        'Template archive contains an unsafe path: ${entry.name}',
      );
    }
    final destination = p.canonicalize(
      p.joinAll([root, ...p.posix.split(normalized)]),
    );
    if (destination != root && !p.isWithin(root, destination)) {
      throw CliException(
        'Template archive escapes its destination: ${entry.name}',
      );
    }
    if (entry.isDirectory) {
      Directory(destination).createSync(recursive: true);
      continue;
    }
    final file = File(destination);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(entry.content, flush: true);
  }
}

bool _isTemplateRoot(String root) =>
    File(p.join(root, 'worker', 'wrangler.jsonc.example')).existsSync() &&
    File(p.join(root, 'admin_dashboard', 'pubspec.yaml')).existsSync() &&
    File(p.join(root, 'web', 'pubspec.yaml')).existsSync();

void _validateVersion(String version) {
  if (!RegExp(r'^[0-9A-Za-z][0-9A-Za-z.-]*$').hasMatch(version)) {
    throw CliException('Invalid template version: $version');
  }
}

Uri _parseHttpUri(String value, String option) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !uri.hasAuthority ||
      (uri.scheme != 'https' && uri.scheme != 'http')) {
    throw CliException('$option must be an absolute HTTP(S) URL.');
  }
  return uri;
}

String _normalizeChecksum(String value, String source) {
  final match = RegExp(r'\b([0-9a-fA-F]{64})\b').firstMatch(value);
  if (match == null) {
    throw CliException('Invalid SHA-256 checksum from $source.');
  }
  return match.group(1)!.toLowerCase();
}
