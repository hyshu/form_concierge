# API documentation coverage

Verified on 2026-09-19.

All 3,154 declared public API entries in the audited source directories have
English documentation comments. Coverage is 100 percent.

| Source directory | Documented | Total | Coverage |
| --- | --- | --- | --- |
| `client/lib` | 608 | 608 | 100% |
| `widget/lib` | 184 | 184 | 100% |
| `cli/lib` | 161 | 161 | 100% |
| `web/lib` | 171 | 171 | 100% |
| `admin_dashboard/lib` | 908 | 908 | 100% |
| `worker/src` | 524 | 524 | 100% |
| `apple/Sources` | 289 | 289 | 100% |
| `android/form-concierge-compose/src/main/kotlin` | 309 | 309 | 100% |
| **Total** | **3,154** | **3,154** | **100%** |

## Audit scope

The audit covers declared public types, constructors, methods, functions,
properties, constants, enum entries, and extension APIs. Dart declarations are
included throughout each library directory, including implementation libraries.
Worker exports include their declared members and locally defined types exposed
through their signatures. Swift and Kotlin members are checked according to
their declared or inherited visibility.

Private implementation details, tests, examples, platform scaffolding, and
compiler-synthesized members are outside the count. Third-party generated
declarations are excluded. The two repository-generated translation tables are
included, and their generator now preserves their documentation comments.

Counts come from Dart analyzer, TypeScript compiler, and Swift and Kotlin syntax
trees. A separate Swift compiler symbol graph check found documentation on all
285 source-located public symbols available in the macOS SwiftUI module.
UIKit declarations were checked in source.

Documentation prose in the audited, repository-owned sources contains no em
dashes, semicolons, or colons.

## Validation

- Dart analysis passed for the client, widget, CLI, web application, and dashboard.
- Dart API documentation generation and link validation passed for all three
  distributable Dart packages with zero warnings and zero errors.
- Client, CLI, widget, and dashboard tests passed with 15, 25, 24, and 75 tests.
- Worker type checking passed along with 141 unit tests and 2 integration tests.
- Swift tests passed with 26 tests.
- Android passed 11 unit tests, release lint, and the release build.
- Changed source files were formatted with Dart format, swift-format, ktlint,
  and Prettier.
- Translation regeneration reproduced the checked-in generated files exactly.
- Token and syntax-tree comparisons confirmed that executable source behavior
  was unchanged by the documentation edits. The localization generator now
  emits comments. The pre-existing Apple platform changes were preserved.

The validation suite passed 319 tests in total. The widget README example link
was changed to a repository URL so it also resolves in generated API documentation.
