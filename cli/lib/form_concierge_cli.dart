import 'dart:io';

import 'package:args/command_runner.dart';

import 'src/cli_exception.dart';
import 'src/doctor_command.dart';
import 'src/setup_command.dart';

export 'src/cli_exception.dart';
export 'src/monorepo.dart';
export 'src/template_resolver.dart'
    show
        TemplateResolver,
        defaultTemplateArchiveUri,
        defaultTemplateCacheRoot,
        formConciergeCliVersion;

/// Entry point for the Form Concierge CLI.
Future<int> runFormConciergeCli(List<String> args) async {
  final runner =
      CommandRunner<int>(
          'form_concierge',
          'Form Concierge tooling (setup, doctor).',
        )
        ..addCommand(DoctorCommand())
        ..addCommand(SetupCommand());

  try {
    final result = await runner.run(args);
    return result ?? 0;
  } on UsageException catch (error) {
    stderr.writeln(error);
    return 64;
  } on CliException catch (error) {
    stderr.writeln(error.message);
    return error.exitCode;
  }
}
