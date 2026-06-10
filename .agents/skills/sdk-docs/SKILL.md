# SDK Docs Skill — frame-ios

Swift-specific DocC authoring rules for the Frame iOS SDK.

## Standards

Delegate to central standards first:

1. **Local** (preferred): `~/Development/frame-docs/lib/sdk-docs-standards/STYLE.md`, `EXAMPLES.md`, `CROSS_SDK_NAMING.md`
2. **Fallback**: https://github.com/framepayments/frame-docs/blob/main/lib/sdk-docs-standards/STYLE.md

If the central standards file is unavailable, apply the Swift-specific rules below and note that central standards should be consulted when available.

## Swift / DocC Rules

### Format

All public symbols require a triple-slash `///` DocC comment. Use `/** */` only when writing multi-paragraph reference docs with structured sections.

```swift
/// A brief one-line summary ending with a period.
///
/// Extended discussion goes here when needed. Keep it concise.
///
/// - Parameters:
///   - param: Description of this parameter.
/// - Returns: What the function returns.
/// - Throws: What errors can be thrown.
public func exampleFunction(param: String) throws -> Bool { ... }
```

### Summary line

- One sentence, imperative mood for functions ("Submits the payment"), noun phrase for types ("A checkout flow coordinator").
- End with a period.
- No redundant prefixes like "This method…" or "A class that…".

### Parameters / Returns / Throws

- Document every parameter, return value, and thrown error on public API.
- Use the structured `- Parameters:` list form (not inline `- Parameter name:`).
- Be specific: say what the value means, not just its type.

### Cross-SDK naming

Match naming used in `frame-android` and `frame-js` for equivalent concepts. Check `CROSS_SDK_NAMING.md` before introducing new terminology.

### What NOT to document

- Implementation details or internal state that leaks nothing useful to callers.
- Obvious initializers where the parameter names are self-documenting (e.g., `init(id: String, name: String)` — omit if there's nothing non-obvious to say).

### Existing symbols

Existing public symbols without doc comments are tracked in [FRA-3958](https://linear.app/framepayments/issue/FRA-3958) (DocC backfill). When touching an undocumented symbol, add a doc comment. New public symbols must always have a doc comment — CI will fail otherwise.

## Lint gate

SwiftLint `missing_docs` rule is enforced on this repo. CI fails on any public symbol missing a `///` comment. Run `swiftlint lint` locally before pushing.
