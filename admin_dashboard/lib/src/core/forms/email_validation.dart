final _emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

bool isValidEmailAddress(String value) {
  return _emailPattern.hasMatch(value.trim());
}
