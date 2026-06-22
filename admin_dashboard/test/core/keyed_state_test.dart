import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_flutter/src/core/capsules/keyed_state.dart';
import 'package:rearch/rearch.dart';

void main() {
  test('keyed state accessors read updates made by the same closure', () {
    final container = CapsuleContainer();
    addTearDown(container.dispose);

    final (getState, setState) = container.read(_keyedCounterStateCapsule);

    expect(getState(1), 0);

    setState(1, 1);

    expect(getState(1), 1);
  });

  test('keyed state updates preserve previous keys from the same closure', () {
    final container = CapsuleContainer();
    addTearDown(container.dispose);

    final (getState, setState) = container.read(_keyedCounterStateCapsule);

    setState(1, 1);
    setState(2, 2);

    expect(getState(1), 1);
    expect(getState(2), 2);
  });
}

KeyedStateAccessors<int, int> _keyedCounterStateCapsule(CapsuleHandle use) {
  return createKeyedState(use, () => 0);
}
