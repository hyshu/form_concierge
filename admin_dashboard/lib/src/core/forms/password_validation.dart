/// The minimum number of characters accepted for an administrator password.
const minimumPasswordLength = 8;

/// Returns whether the password meets the minimum length requirement.
bool hasMinimumPasswordLength(String value) =>
    value.length >= minimumPasswordLength;
