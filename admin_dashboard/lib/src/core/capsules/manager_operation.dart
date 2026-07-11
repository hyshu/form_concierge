Future<T?> runAndReload<T>({
  required Future<T> Function() action,
  required Future<void> Function() reload,
  required void Function(String error) setError,
  required String errorMessage,
}) async {
  final T result;
  try {
    result = await action();
  } on Exception catch (e) {
    setError('$errorMessage: $e');
    return null;
  }
  // The mutation succeeded; a reload failure must not look like a mutation
  // failure, or retrying would duplicate the operation.
  try {
    await reload();
  } on Exception catch (e) {
    setError('The change was saved, but refreshing the list failed: $e');
  }
  return result;
}

Future<bool> runVoidAndReload({
  required Future<void> Function() action,
  required Future<void> Function() reload,
  required void Function(String error) setError,
  required String errorMessage,
}) async {
  final result = await runAndReload(
    action: () async {
      await action();
      return true;
    },
    reload: reload,
    setError: setError,
    errorMessage: errorMessage,
  );
  return result ?? false;
}
