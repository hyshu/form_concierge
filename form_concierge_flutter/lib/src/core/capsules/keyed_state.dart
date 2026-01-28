import 'package:rearch/rearch.dart';

typedef KeyedStateAccessors<K, S> = (
  S Function(K key) getState,
  void Function(K key, S state) setState,
);

KeyedStateAccessors<K, S> createKeyedState<K, S>(
  CapsuleHandle use,
  S Function() createInitialState,
) {
  final (stateMap, setStateMap) = use.state<Map<K, S>>({});

  S getState(K key) {
    return stateMap[key] ?? createInitialState();
  }

  void setState(K key, S state) {
    setStateMap({...stateMap, key: state});
  }

  return (getState, setState);
}
