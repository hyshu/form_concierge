final _emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

bool isValidEmailAddress(String value) => _emailPattern.hasMatch(value.trim());
