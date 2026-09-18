/// Throws UnsupportedError because file downloads require the web implementation.
Future<void> downloadFile({
  required List<int> bytes,
  required String filename,
  required String contentType,
}) => throw UnsupportedError('File downloads are only available on web.');
