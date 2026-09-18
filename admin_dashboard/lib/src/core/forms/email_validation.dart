final _emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

/// Returns whether the trimmed value matches the application's email pattern.
bool isValidEmailAddress(String value) => _emailPattern.hasMatch(value.trim());
