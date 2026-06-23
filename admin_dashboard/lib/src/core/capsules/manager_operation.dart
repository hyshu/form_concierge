Future<T?> runAndReload<T>({
  required Future<T> Function() action,
  required Future<void> Function() reload,
  required void Function(String error) setError,
  required String errorMessage,
}) async {
  try {
    final result = await action();
    await reload();
    return result;
  } on Exception catch (e) {
    setError('$errorMessage: $e');
    return null;
  }
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
