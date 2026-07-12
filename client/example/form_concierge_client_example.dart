import 'package:form_concierge_client/form_concierge_client.dart';

Future<void> main() async {
  final client = Client('https://your-worker.example.com');
  try {
    final project = await client.survey.getProjectBySlug('demo-project');
    print(project?.project.name);
  } finally {
    client.close();
  }
}
