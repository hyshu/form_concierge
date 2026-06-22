import 'package:rearch/rearch.dart';

typedef KeyedStateAccessors<K, S> = (
  S Function(K key) getState,
  void Function(K key, S state) setState,
);

KeyedStateAccessors<K, S> createKeyedState<K, S>(
  CapsuleHandle use,
  S Function() createInitialState,
) {
  final (getStateMap, setStateMap) = use.data<Map<K, S>>({});

  S getState(K key) {
    return getStateMap()[key] ?? createInitialState();
  }

  void setState(K key, S state) {
    final stateMap = getStateMap();
    setStateMap({...stateMap, key: state});
  }

  return (getState, setState);
}
