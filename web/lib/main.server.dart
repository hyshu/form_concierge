import 'dart:io';

import 'package:jaspr/server.dart';
import 'package:jaspr/dom.dart';

import 'app.dart';
import 'main.server.options.dart';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);

  final serverUrl =
      Platform.environment['FORM_CONCIERGE_API_URL'] ?? 'http://localhost:8787';

  runApp(Document(
    title: 'Form Concierge',
    lang: 'ja',
    base: '/',
    meta: {
      'description': 'Web Survey Form',
      'viewport': 'width=device-width, initial-scale=1.0',
    },
    head: [
      link(href: '/styles.css', rel: 'stylesheet'),
    ],
    body: App(serverUrl: serverUrl),
  ));
}
