import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> downloadFile({
  required List<int> bytes,
  required String filename,
  required String contentType,
}) async {
  final blob = web.Blob(
    [Uint8List.fromList(bytes).toJS].toJS,
    web.BlobPropertyBag(type: contentType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
