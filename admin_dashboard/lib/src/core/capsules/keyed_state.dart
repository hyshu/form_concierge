import 'package:rearch/rearch.dart';

/// Callbacks for reading and replacing state associated with a key.
typedef KeyedStateAccessors<K, S> = (
  S Function(K key) getState,
  void Function(K key, S state) setState,
);

/// Creates read and update callbacks for state stored by key.
KeyedStateAccessors<K, S> createKeyedState<K, S>(
  CapsuleHandle use,
  S Function() createInitialState,
) {
  final (getStateMap, setStateMap) = use.data<Map<K, S>>({});

  S getState(K key) => getStateMap()[key] ?? createInitialState();

  void setState(K key, S state) {
    final stateMap = getStateMap();
    setStateMap({...stateMap, key: state});
  }

  return (getState, setState);
}
