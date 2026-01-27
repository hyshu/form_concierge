# UI Baseline Rules

These rules MUST be followed for all UI work. Use `/baseline-ui` for the full constraint set.

## Critical Rules (NEVER violate)

- NEVER add animation unless explicitly requested by the user
- NEVER use gradients unless explicitly requested
- NEVER use hardcoded colors - use `Theme.of(context).colorScheme` in Flutter
- NEVER block paste in text input fields (TextField, TextFormField, input, textarea)
- NEVER rebuild keyboard/focus behavior by hand when framework widgets provide it
- NEVER use `setState` inside `build` method in Flutter
- NEVER create widgets inside loops without keys in Flutter

## Required Patterns (MUST follow)

- MUST use `AlertDialog` for destructive or irreversible actions
- MUST use `SafeArea` for screens with system UI overlap in Flutter
- MUST use `const` constructors where possible in Flutter
- MUST add `semanticLabel` to icon-only buttons for accessibility
- MUST show errors next to the action that caused them, not in a generic location
- MUST use theme tokens instead of hardcoded color/size values
- MUST respect reduced motion preferences (`MediaQuery.disableAnimations` in Flutter, `prefers-reduced-motion` in CSS)

## Performance Rules

- MUST use `ListView.builder` for long lists instead of `ListView` in Flutter
- MUST avoid expensive operations in `build` method
- SHOULD keep animation duration under 200ms for interaction feedback

## Design Principles

- Empty states MUST have one clear next action
- Limit accent color usage to one per screen/view
- Use Material elevation instead of custom shadows in Flutter
