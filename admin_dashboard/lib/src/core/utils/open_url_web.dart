import 'package:web/web.dart' as web;

/// Opens [url] in a new browser tab.
void openUrl(String url) {
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..target = '_blank'
    ..rel = 'noopener noreferrer';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
