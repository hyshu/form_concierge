import 'dart:io';

import 'package:form_concierge_cli/form_concierge_cli.dart';

Future<void> main(List<String> args) async {
  final code = await runFormConciergeCli(args);
  exit(code);
}
