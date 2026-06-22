import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import 'src/app.dart';

late final Client client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final serverUrl = await _getApiUrl();
  client = Client(serverUrl);

  runApp(const RearchBootstrapper(child: App()));
}

Future<String> _getApiUrl() async {
  try {
    final raw = await rootBundle.loadString('assets/config.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return json['apiUrl'] as String? ?? 'http://localhost:8787';
  } catch (_) {
    return 'http://localhost:8787';
  }
}
