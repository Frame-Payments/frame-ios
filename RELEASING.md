# Releasing the Frame iOS SDK

This doc covers how to cut a release of the Frame iOS SDK for both Swift Package Manager and CocoaPods.

The SDK is split across two repositories:

| Repo | Pods published to trunk | Why |
|---|---|---|
| `Frame-Payments/evervault-ios` (fork) | `Frame-EvervaultCore`, `Frame-EvervaultInputs` | Upstream Evervault ships SPM-only. Our fork adds podspecs so the Frame SDK has CocoaPods-compatible deps. |
| `Frame-Payments/frame-ios` | *(none — distributed by git tag, see below)* | The SDK itself. |

The fork repo doesn't need a release every time the Frame SDK does — only when upstream Evervault publishes a new version we want to pick up, or when the podspecs themselves need changes.

---

## Distribution model

### `Frame-iOS` and `Frame-Onboarding` — git tag, not trunk

Both pods are consumed via `pod 'Frame-iOS', :git => '...', :tag => '...'` rather than published to public CocoaPods trunk. This is intentional:

- `Frame-Onboarding` depends on `ProveAuth`, which lives in Prove's private Artifactory spec repo. Trunk's server-side validator can't resolve private spec repos, so `Frame-Onboarding` can't be pushed to trunk at all.
- We keep `Frame-iOS` on the same distribution model so both pods always release in lockstep — consumers pin both to the same git tag, eliminating the possibility of a version skew between them.

The release flow for these two pods is simply: bump the version in both podspecs, commit, tag on GitHub. There's no `pod trunk push` step.

### `Frame-EvervaultCore` and `Frame-EvervaultInputs` — trunk

These have no private dependencies and benefit from being discoverable, so they're published to public CocoaPods trunk normally. See [the Evervault fork release flow](#releasing-the-evervault-fork-frame-evervaultcore--frame-evervaultinputs) below.

---

## Versioning

### `Frame-iOS` and `Frame-Onboarding`
Standard SemVer. They release in lockstep (same version number) because Onboarding declares `s.dependency 'Frame-iOS', "= #{s.version}"`.

- **Patch** (3.0.0 → 3.0.1): bug fixes, internal refactors, no API changes.
- **Minor** (3.0.0 → 3.1.0): new features, new public APIs, no breaking changes.
- **Major** (3.0.0 → 4.0.0): breaking API changes, dropping support for an iOS version, removing public types/methods.

### `Frame-EvervaultCore` and `Frame-EvervaultInputs`
Versioned as `<upstream-tag>-frame.<n>`:
- `<upstream-tag>` mirrors the upstream Evervault release we forked from (e.g. `2.1.0`)
- `frame.<n>` increments every time we ship a new podspec for that upstream version

Examples:
- `2.1.0-frame.1` — first podspec built on upstream 2.1.0
- `2.1.0-frame.2` — same upstream source, podspec fix (static_framework added)
- `2.1.0-frame.3` — same upstream source, podspec fix (module_name added)
- `2.2.0-frame.1` — rebased onto a new upstream 2.2.0 tag

Both fork pods always share the same version (Inputs depends on Core with an exact pin).

---

## Releasing the Frame SDK (`Frame-iOS` + `Frame-Onboarding`)

Most releases are this — the Evervault fork only needs touching when upstream Evervault ships a version we want to consume.

### 1. Land your changes
Commit and merge your work into `main` via your usual PR flow. Make sure the `.github/workflows/podspec-lint.yml` workflow passes on the PR.

### 2. Bump the version in both podspecs
Edit `Frame-iOS.podspec` and `Frame-Onboarding.podspec`:
```ruby
s.version = '3.1.0'  # bump in both files
```
They must match — Onboarding's `Frame-iOS` dep uses `= #{s.version}`.

### 3. Pre-lint locally (recommended)
Catch podspec issues before tagging.

```bash
cd ~/Documents/GitHub/frame-ios
pod lib lint Frame-iOS.podspec --allow-warnings
```

If you've also changed the Evervault fork and haven't pushed it yet, point at the local fork:
```bash
pod lib lint Frame-iOS.podspec --allow-warnings \
  "--include-podspecs=/Users/erictownsend/Documents/GitHub/evervault-ios/{Frame-EvervaultCore,Frame-EvervaultInputs}.podspec"
```

`Frame-Onboarding` can't be fully linted because `ProveAuth` lives in Prove's private Artifactory spec repo. Best you can do is validate the podspec syntax:
```bash
pod ipc spec Frame-Onboarding.podspec > /dev/null && echo "OK"
```

### 4. Commit the version bumps
```bash
git add Frame-iOS.podspec Frame-Onboarding.podspec
git commit -m "chore: bump podspec version to 3.1.0"
```
Push and merge to main.

### 5. Tag and publish on GitHub
Via GitHub web (https://github.com/Frame-Payments/frame-ios):
- Releases → **Draft a new release**
- Tag: `3.1.0` (matches podspec `s.version`)
- Target: `main`
- Title: `3.1.0`
- Description: bulleted summary of changes
- **Publish release**

That's it — once the tag exists on origin, consumers can install the new version by updating their `:tag =>` value:
```ruby
pod 'Frame-iOS',        :git => 'https://github.com/Frame-Payments/frame-ios.git', :tag => '3.1.0'
pod 'Frame-Onboarding', :git => 'https://github.com/Frame-Payments/frame-ios.git', :tag => '3.1.0'
```

CocoaPods reads the podspec directly from the tagged commit, so the version in `s.version` must match the git tag exactly.

### 6. Verify
Have a consumer project run `pod install` (or `pod update Frame-iOS Frame-Onboarding`) against the new tag and confirm it resolves cleanly. SPM consumers will pick up the same tag through their package resolution.

---

## Releasing the Evervault fork (`Frame-EvervaultCore` + `Frame-EvervaultInputs`)

Only needed when upstream Evervault publishes a version we want to consume, or when the podspecs themselves need a fix. These pods *are* published to public CocoaPods trunk — they have no private dependencies and the discoverability matters for the Frame SDK to resolve them.

### Prerequisite

Authenticate to CocoaPods trunk (one-time per machine):
```bash
pod trunk register engineering@framepayments.com 'Frame Payments' --description='laptop'
pod trunk me  # verify
```

### When upstream Evervault releases a new version

1. **Rebase onto the new upstream tag** in `~/Documents/GitHub/evervault-ios`:
   ```bash
   git fetch upstream
   git rebase <upstream-tag>  # e.g. 2.2.0
   ```
   Resolve any conflicts (rare — we only touch podspecs and one localization helper file).

2. **Bump both podspec versions** to `<new-upstream-tag>-frame.1`:
   ```ruby
   s.version = '2.2.0-frame.1'  # in both Frame-EvervaultCore.podspec and Frame-EvervaultInputs.podspec
   ```

3. **Check for new `Bundle.module` references in `Sources/EvervaultInputs/`** — if upstream added any, wire them through the `EvervaultInputsResourceBundle` helper in `LocalizedString.swift` (guarded by `#if SWIFT_PACKAGE`).

4. **Pre-lint locally:**
   ```bash
   cd ~/Documents/GitHub/evervault-ios
   pod lib lint Frame-EvervaultCore.podspec --allow-warnings
   pod lib lint Frame-EvervaultInputs.podspec --allow-warnings \
     --include-podspecs=Frame-EvervaultCore.podspec
   ```

5. **Commit, push, tag, and release** on GitHub:
   - Tag: `2.2.0-frame.1`
   - GitHub web → Releases → Draft a new release

6. **Push Core first, wait for CDN propagation, then push Inputs:**
   ```bash
   pod trunk push Frame-EvervaultCore.podspec --allow-warnings

   # Wait for CDN — Core shard is 6/9/0
   while ! curl -s "https://cdn.cocoapods.org/all_pods_versions_6_9_0.txt" | grep -q "Frame-EvervaultCore.*2.2.0-frame.1"; do
     echo "waiting..." ; sleep 60
   done

   pod trunk push Frame-EvervaultInputs.podspec --allow-warnings
   ```

   The CDN version index lags `pod trunk push` by 15–60 minutes. If you push Inputs before Core has propagated, validation fails with "Unable to find a specification for `Frame-EvervaultCore (= 2.2.0-frame.1)`".

7. **Bump the fork dep pin in `Frame-iOS.podspec`** in the SDK repo:
   ```ruby
   s.dependency 'Frame-EvervaultCore', '~> 2.2.0-frame.1'
   s.dependency 'Frame-EvervaultInputs', '~> 2.2.0-frame.1'
   ```
   Then cut a new Frame SDK release using the flow above.

### When you just need to fix a podspec issue

Same flow, but bump only the `-frame.<n>` suffix:
- `2.1.0-frame.3` → `2.1.0-frame.4`

You can't republish the same version on trunk — every fix needs a version bump.

### Skip upstream releases that only touch `EvervaultEnclaves`

We intentionally don't ship `Frame-EvervaultEnclaves`. If an upstream release only changes Enclaves code, there's no reason to cut a new fork release.

---

## Troubleshooting

### Consumer reports "Unable to find a specification for `ProveAuth`"
They haven't installed `cocoapods-art` or registered Prove's spec repo. Point them to the [CocoaPods setup section in the README](README.md#cocoapods).

### Consumer reports their pods are stuck on an old version
`:git => :tag =>` pins to an exact tag — `pod update` won't move them forward on its own. They need to edit the `:tag =>` value in their Podfile to the new release, then run `pod install`. (This is the lockstep-by-design behavior; surface it as such, not as a bug.)

### "The 'Pods-App' target has transitive dependencies that include statically linked binaries"
A dependency in the chain ships as a static framework (e.g. `EvervaultPayment`). Add `s.static_framework = true` to the podspec at the level that depends on it. This is already set on `Frame-EvervaultInputs`, `Frame-iOS`, and `Frame-Onboarding` — leave it that way.

### "Unable to resolve module dependency: 'EvervaultCore'"
The pod name (`Frame-EvervaultCore`) doesn't match the Swift module name consumers `import`. Make sure `s.module_name = 'EvervaultCore'` is set on the podspec. Already set on both Evervault fork podspecs.

### "type 'Bundle' has no member 'module'"
Source uses SPM-only `Bundle.module`. Under CocoaPods, resources go into a resource bundle. Guard the reference with `#if SWIFT_PACKAGE` and provide a CocoaPods fallback (see `FrameResources.module` in `Sources/Frame/Networking/CommonObjects.swift` for the pattern).

### "The spec did not pass validation, due to 1 warning" (Evervault trunk push)
The default linter rejects warnings. Add `--allow-warnings` to the `pod trunk push` command.

### "Unable to find a specification for `Frame-EvervaultCore (= X)`" when pushing Inputs
Core hasn't propagated to the CDN version index yet. Wait — the index lags `pod trunk push` by 15–60 minutes for new versions. Shard for both Evervault pods is `6/9/0` (Core) and `9/0/0` (Inputs):
```bash
curl -s "https://cdn.cocoapods.org/all_pods_versions_6_9_0.txt" | grep Frame-EvervaultCore
```

### Pre-commit hook rewrote my commit message
The repo has a hook that enforces a commit message convention. If your message gets replaced unexpectedly, check `.git/hooks/` or the project's commit-msg config.
