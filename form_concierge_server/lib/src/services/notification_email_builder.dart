import 'response_summary_service.dart';

/// Builds email content for daily notification emails.
class NotificationEmailBuilder {
  /// Build plain text email body.
  static String buildTextBody(DailyResponseSummary summary) {
    final buffer = StringBuffer();

    buffer.writeln('Daily Response Summary: ${summary.survey.title}');
    buffer.writeln('=' * 50);
    buffer.writeln();
    buffer.writeln(
      'New responses in the last 24 hours: ${summary.responseCount}',
    );
    buffer.writeln();

    if (summary.aiSummary != null) {
      buffer.writeln('AI Summary:');
      buffer.writeln('-' * 30);
      buffer.writeln(summary.aiSummary);
      buffer.writeln();
      buffer.writeln('-' * 50);
      buffer.writeln();
    }

    if (summary.responses.isEmpty) {
      buffer.writeln('No new responses to report.');
    } else {
      for (var i = 0; i < summary.responses.length; i++) {
        final detail = summary.responses[i];
        buffer.writeln(
          'Response ${i + 1} (${_formatDateTime(detail.response.submittedAt)}):',
        );
        for (final answer in detail.answers) {
          buffer.writeln('  ${answer.questionText}');
          buffer.writeln('    ${answer.displayValue}');
        }
        buffer.writeln();
      }
    }

    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('This is an automated notification from Form Concierge.');

    return buffer.toString();
  }

  /// Build HTML email body.
  static String buildHtmlBody(DailyResponseSummary summary) {
    final responses = summary.responses;

    final responsesHtml = responses.isEmpty
        ? '<p class="no-responses">No new responses to report.</p>'
        : responses
              .asMap()
              .entries
              .map((entry) {
                final answersHtml = entry.value.answers
                    .map(
                      (a) =>
                          '''
      <div class="question">${_escapeHtml(a.questionText)}</div>
      <div class="answer">${_escapeHtml(a.displayValue)}</div>''',
                    )
                    .join('\n');

                return '''
    <div class="response">
      <div class="response-header">Response ${entry.key + 1} - ${_formatDateTime(entry.value.response.submittedAt)}</div>
      $answersHtml
    </div>''';
              })
              .join('\n');

    final aiSummaryHtml = summary.aiSummary != null
        ? '''
  <div class="ai-summary">
    <strong>AI Summary:</strong>
    <p>${_escapeHtml(summary.aiSummary!)}</p>
  </div>'''
        : '';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      max-width: 800px;
      margin: 0 auto;
      padding: 20px;
      background-color: #f5f5f5;
      color: #333;
    }
    .container {
      background: #fff;
      border-radius: 8px;
      padding: 24px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    }
    h1 {
      color: #1a1a1a;
      border-bottom: 2px solid #6366f1;
      padding-bottom: 12px;
      margin-top: 0;
      font-size: 24px;
    }
    .summary-box {
      background: #f8f9fa;
      border-left: 4px solid #6366f1;
      padding: 16px;
      margin: 20px 0;
      border-radius: 0 4px 4px 0;
    }
    .ai-summary {
      background: #eff6ff;
      border-left: 4px solid #3b82f6;
      padding: 16px;
      margin: 20px 0;
      border-radius: 0 4px 4px 0;
    }
    .ai-summary p {
      margin: 8px 0 0 0;
      line-height: 1.6;
    }
    .response {
      background: #fff;
      border: 1px solid #e5e7eb;
      border-radius: 6px;
      padding: 16px;
      margin: 16px 0;
    }
    .response-header {
      color: #6b7280;
      font-size: 12px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 12px;
      padding-bottom: 8px;
      border-bottom: 1px solid #e5e7eb;
    }
    .question {
      font-weight: 600;
      color: #374151;
      margin-top: 12px;
      font-size: 14px;
    }
    .answer {
      color: #1f2937;
      margin-left: 16px;
      padding: 8px 0;
      font-size: 14px;
      line-height: 1.5;
    }
    .no-responses {
      color: #6b7280;
      font-style: italic;
      padding: 20px;
      text-align: center;
    }
    .footer {
      color: #9ca3af;
      font-size: 12px;
      margin-top: 32px;
      padding-top: 16px;
      border-top: 1px solid #e5e7eb;
      text-align: center;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>${_escapeHtml(summary.survey.title)}</h1>

    <div class="summary-box">
      <strong>New responses in the last 24 hours:</strong> ${summary.responseCount}
    </div>

    $aiSummaryHtml

    $responsesHtml

    <div class="footer">
      This is an automated notification from Form Concierge.
    </div>
  </div>
</body>
</html>
''';
  }

  static String _formatDateTime(DateTime dt) {
    final utc = dt.toUtc();
    return '${utc.year}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')} '
        '${utc.hour.toString().padLeft(2, '0')}:${utc.minute.toString().padLeft(2, '0')} UTC';
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
