---
name: form-concierge-publish
description: Prepare, validate, publish, and verify Form Concierge releases across pub.dev, SwiftPM, and GitHub. Use for version bumps, release commits, publishing client/widget/CLI packages, validating the Swift package, creating version tags and GitHub Release assets, or recovering from a partial publish. Enforces review gates and the required client-to-widget propagation wait.
---

# Publish Form Concierge

Release Form Concierge without skipping dependency propagation, publishing the
CLI before its template exists, or changing Git history without approval.

## Non-negotiable rules

- Treat every pub.dev publish as irreversible. Never publish speculatively or
  retry a package whose version may already be live.
- Do not commit, push, tag, publish, rewrite history, or create a release until
  the user has reviewed the relevant state and explicitly approved that stage.
  A generic “continue” only applies to the stage that was just presented.
- Before each approval request, show the exact diff or release state, the
  proposed commands, and which external state they will change.
- Preserve unrelated user changes. Never mix them into a release commit.
- Do not use `git reset`, `git revert`, commit amendment, tag deletion, or force
  push to correct an agent mistake without explicit user direction. Stop and
  present the safest options first.
- Follow repository `AGENTS.md` instructions. Format every changed source file.
- Use `tool/publish.sh`; do not manually reproduce its publish sequence.

## Establish release scope

1. Run `git status --short --branch`, inspect recent commits and tags, and read
   `AGENTS.md`, `README.md`, `tool/publish.sh`, and the release workflows.
2. Determine the requested version and included changes from the conversation
   and repository. Ask only if the version or scope is genuinely unknown; never
   infer patch versus minor.
3. Inventory changes since the previous tag for every component, including the
   admin dashboard and SwiftUI package. Classify Cloudflare template changes as
   Secrets, D1 migrations, Worker, Admin Pages, or Web Pages. Compare changelog
   style with the other packages.
4. Present a release-preparation plan before editing. Explicitly separate:
   - historical changelog backfills through the previous release;
   - unrelated housekeeping such as `.gitignore` changes;
   - the current version bump, current changelogs, locks, and release docs.
5. Historical backfills and unrelated housekeeping must use commits separate
   from the current release commit unless the user explicitly requests another
   grouping.

## Prepare the release

Update all applicable version references consistently:

- `client/pubspec.yaml`
- `widget/pubspec.yaml`
- the hosted `form_concierge_client: ^VERSION` dependency in
  `widget/pubspec.yaml`
- `cli/pubspec.yaml`
- `formConciergeCliVersion` in `cli/lib/src/template_resolver.dart`
- the target version entry in
  `cli/lib/src/cloudflare/cloudflare_release_manifest.dart`
- `admin_dashboard/pubspec.yaml`, preserving its build-number convention
- the root `README.md` package table and versioned tag/release examples
- `client/CHANGELOG.md`
- `widget/CHANGELOG.md`
- `cli/CHANGELOG.md`
- `admin_dashboard/CHANGELOG.md`
- `swiftui/README.md` and Swift package release notes when SwiftUI or SwiftPM
  behavior changed
- tracked lockfiles changed by dependency resolution

Describe actual user-visible changes in each changelog. Do not add repetitive
release-process bullets such as “Use the VERSION GitHub Release template for
standalone installs” on every release; fold meaningful behavior into the
relevant feature entry.

Build the Cloudflare release-manifest entry from the actual diff between the
previous release tag and the release commit. Each entry describes work
introduced by that version, not a cumulative full-deploy list:

- `secrets`: required secret names, Secrets Store bindings, or Worker secret
  requirements changed;
- `d1Migrations`: files under `worker/migrations/` changed;
- `worker`: Worker source, runtime bindings, or deploy-time Worker config
  changed;
- `adminPages`: deployable Admin dashboard code or assets changed;
- `webPages`: deployable public web code or assets changed.

Include every published CLI/template version in the manifest, even when its
component set is empty. Use all components for the first public template. When
a change crosses component boundaries or classification is uncertain, include
every affected component rather than risk an incomplete update. Keep the
human-readable table in `cli/README.md` synchronized with the manifest.

Run package resolution where required and inspect every resulting lockfile
change. Format changed Dart files with `dart format` before validation.

SwiftPM versions come from Git tags; do not add a version to `Package.swift`.
When preparing the first release whose tag contains the root `Package.swift`,
describe it as the first version-resolvable SwiftPM release. Older tags remain
unavailable through SwiftPM even if the package exists on a later branch.

## Validate and obtain release-commit approval

1. Run `bash tool/ci/static_checks.sh`.
2. Confirm `cli/test/deployment_plan_test.dart` passes and verifies that the
   current CLI version has a manifest entry. Review the previous-tag diff
   against the manifest entry before accepting the result.
3. Run publish dry-runs for `client`, `widget`, and `cli`, reviewing every file
   in each package. For the widget dry-run, temporarily shelve the tracked
   `widget/pubspec_overrides.yaml` exactly as `tool/publish.sh` does, restore it
   even on failure, then refresh local dependencies.
4. Run `tool/publish.sh --plan client widget` and
   `tool/publish.sh --plan cli` to confirm the intended order.
5. If the root `Package.swift` exists, validate the package and example:

   ```bash
   swift package dump-package
   swift test
   xcodebuild \
     -project swiftui/Examples/FormConciergeExample/FormConciergeExample.xcodeproj \
     -scheme FormConciergeExample \
     -destination 'generic/platform=iOS Simulator' \
     CODE_SIGNING_ALLOWED=NO \
     build
   ```

   Confirm the library product is `FormConciergeSwiftUI`, root-manifest target
   paths resolve, and validation leaves no tracked build artifacts.
6. Re-run `git status --short` and inspect the full diff. Confirm there are no
   generated, shelved, or credential files left behind.
7. Present the proposed commit grouping and messages. Wait for explicit
   approval before committing.
8. After committing, show the commit SHA and clean status. Wait for explicit
   approval before pushing unless that push was already unambiguously approved.
9. Wait for CI on the exact release commit. If CI passes and no files changed
   afterward, do not repeat the full local suite merely for reassurance.

## Publish client and widget

Obtain explicit approval for the irreversible pub.dev stage, then run:

```bash
tool/publish.sh client widget
```

Keep both packages in the same invocation. The script publishes the client,
then waits 600 seconds, then publishes the widget. Do not split the commands,
skip the wait, background the sleep, or infer solver readiness from the pub.dev
HTTP API alone. The Dart package solver index can lag behind the API.

At each interactive prompt:

1. Inspect the package file list and validation output.
2. Confirm the version and hosted dependency resolution.
3. Answer `y` only when the output is expected and the user has authorized this
   publish stage.

For the widget, `tool/publish.sh` temporarily removes the tracked
`pubspec_overrides.yaml` so resolution uses the hosted client. A validator
warning caused solely by that tracked file being temporarily absent/ignored is
expected. Do not add `.pubignore`, edit package contents, or create a workaround
commit merely to suppress it. Stop on any other warning or unexpected
dependency resolution.

Afterward, query pub.dev and confirm that both
`form_concierge_client` and `form_concierge` report `VERSION` as latest.

## Create the GitHub release assets

Only after client and widget are live:

1. Confirm `HEAD` is the approved release commit, matches `origin/main`, and the
   worktree is clean.
2. If the root `Package.swift` exists, confirm it is included in the approved
   release commit. Create the lightweight `vVERSION` tag used by this repository,
   show its target, and verify `git show vVERSION:Package.swift` matches the
   manifest at `HEAD` before pushing it.
3. Obtain approval, then push only that tag.
4. Verify the remote tag with
   `git ls-remote --tags origin refs/tags/vVERSION`. In a temporary consumer
   package, declare the repository URL with `exact: "VERSION"`, run
   `swift package resolve`, and confirm the `FormConciergeSwiftUI` product is
   available. Remove the temporary package afterward.
5. Wait for `.github/workflows/release-template.yml` on the tag to finish
   successfully.
6. Inspect the GitHub Release and require both uploaded assets:
   - `form-concierge-template-VERSION.tar.gz`
   - `form-concierge-template-VERSION.tar.gz.sha256`
7. Confirm the assets are downloadable and have non-empty metadata/digests.

Do not publish the CLI before these assets exist. Standalone CLI installs
download the version-matched release template and checksum.

## Publish the CLI

Obtain explicit approval for the final irreversible publish, then run:

```bash
tool/publish.sh cli
```

Inspect the prompt before answering `y`. Confirm
`form_concierge_cli` reports `VERSION` as latest on pub.dev.

## Recover from partial failures

- If client published but widget failed, do not republish client. Verify the
  client version, allow the solver index more time, then run only
  `tool/publish.sh widget` after approval.
- If a publish result is unclear, query pub.dev before retrying. A timeout or
  lost terminal does not prove the upload failed.
- If the tag workflow fails, fix the underlying source or workflow through a
  user-approved commit and release plan. Never silently retarget or replace a
  published tag.
- If release assets are missing, do not publish CLI. Diagnose the workflow and
  preserve the already-published packages.
- If an accidental local commit is unpushed, stop and show its diff plus safe
  removal options. If it is pushed, explicitly state that remote history would
  change and wait for direction.

## Report completion

Provide:

- release commit SHA and `vVERSION` tag target;
- CI and release-workflow results;
- direct links to all three pub.dev package versions and the GitHub Release;
- names of both release assets;
- confirmation that `main == origin/main`, `vVERSION == HEAD`, and the worktree
  is clean;
- SwiftPM exact-version resolution and `FormConciergeSwiftUI` product
  verification when the root manifest exists;
- any deliberately deferred or partially published component.
