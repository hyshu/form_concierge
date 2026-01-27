---
name: baseline-ui
description: Enforces an opinionated UI baseline to prevent AI-generated interface slop.
---

# Baseline UI

Enforces an opinionated UI baseline to prevent AI-generated interface slop.

## How to use

- `/baseline-ui`
  Apply these constraints to any UI work in this conversation.

- `/baseline-ui <file>`
  Review the file against all constraints below and output:
  - violations (quote the exact line/snippet)
  - why it matters (1 short sentence)
  - a concrete fix (code-level suggestion)

---

## Flutter

### Stack

- MUST use Flutter's Material 3 design system
- MUST use theme tokens from `ThemeData` instead of hardcoded colors/sizes
- SHOULD use `flutter_rearch` or `rearch` for state management if adopted by project
- MUST follow Serverpod client patterns for API communication

### Components

- MUST use Material widgets with proper `Semantics` for accessibility
- MUST add `semanticLabel` or `Semantics` wrapper to icon-only buttons
- MUST use `FocusNode` and `FocusScope` properly for keyboard navigation
- NEVER rebuild focus/keyboard behavior by hand when Material widgets provide it
- SHOULD use `Form` and `FormField` widgets for input validation

### Interaction

- MUST use `showDialog` with `AlertDialog` for destructive actions
- MUST use `Shimmer` or skeleton widgets for loading states
- MUST show `SnackBar` or inline errors next to the action that caused them
- NEVER block paste in `TextField` or `TextFormField`
- MUST handle back button and system gestures appropriately

### Animation

- NEVER add animation unless explicitly requested
- MUST use `AnimatedContainer`, `AnimatedOpacity`, or `AnimatedBuilder` for simple animations
- SHOULD keep animation duration under 200ms for interaction feedback
- MUST respect `MediaQuery.disableAnimations` for reduced motion
- NEVER animate during build phase or inside `setState` synchronously
- SHOULD use `Curves.easeOut` for entrance animations

### Typography

- MUST use `Theme.of(context).textTheme` for text styles
- MUST use `TextOverflow.ellipsis` or `maxLines` for constrained text
- SHOULD use `SelectableText` when users may need to copy content

### Layout

- MUST use `SafeArea` for screens with system UI overlap
- MUST use `MediaQuery` for responsive layouts
- SHOULD use `LayoutBuilder` or `Flex` widgets over fixed dimensions
- NEVER use hardcoded pixel values for responsive elements
- MUST use `Expanded` or `Flexible` instead of fixed sizes in flex layouts

### Performance

- NEVER use `setState` in `build` method
- MUST use `const` constructors where possible
- SHOULD use `ListView.builder` for long lists instead of `ListView`
- NEVER create widgets inside loops without keys
- MUST avoid expensive operations in `build` method

### Design

- NEVER use gradients unless explicitly requested
- MUST use `Theme.of(context).colorScheme` for colors
- MUST give empty states one clear action (`ElevatedButton` or equivalent)
- SHOULD limit accent color usage to one per screen
- NEVER use custom shadows when Material elevation suffices

---

## Docusaurus / React (docs)

### Stack

- MUST use CSS Modules or Docusaurus's built-in styling
- SHOULD use `clsx` for conditional class logic
- MUST follow Docusaurus component patterns for custom components

### Components

- MUST use semantic HTML (`<nav>`, `<main>`, `<article>`, etc.)
- MUST add `aria-label` to icon-only buttons
- SHOULD use Docusaurus's built-in components (`Tabs`, `Admonitions`, etc.) first

### Interaction

- MUST use structural skeletons for async content loading
- MUST show errors inline near the triggering action
- NEVER block paste in input elements

### Animation

- NEVER add animation unless explicitly requested
- SHOULD use CSS transitions over JavaScript animations
- MUST respect `prefers-reduced-motion`
- NEVER exceed 200ms for interaction feedback

### Typography

- SHOULD use Docusaurus's default typography scale
- MUST use proper heading hierarchy (h1 > h2 > h3)

### Performance

- NEVER use `useEffect` for anything expressible as render logic
- SHOULD lazy-load heavy components with `React.lazy`

### Design

- NEVER use gradients unless explicitly requested
- MUST follow Docusaurus theming for light/dark mode
- SHOULD use existing CSS variables before introducing new ones
