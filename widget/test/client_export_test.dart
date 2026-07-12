import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge/client.dart';

void main() {
  test('client entrypoint exports the Dart client API', () {
    final client = Client('https://api.example.com');
    addTearDown(client.close);

    expect(client.baseUri, Uri.parse('https://api.example.com'));
    expect(client.survey, isA<SurveyEndpoint>());
  });
}
