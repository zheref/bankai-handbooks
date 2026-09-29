<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 09 — Design System

Implements **UZF-5** (components are domain-less) and **SW-5** (Design components
are plain SwiftUI, no TCA, no `@Dependency`, no domain types; join PreviewHost).
Previews/snapshots follow **UZF-18** (≥3 previews + ≥3 snapshots).

## Repo-specific placeholders

| Token | Illustrative value | What it is |
| --- | --- | --- |
| `{{APP_TARGET_IOS}}` | `Acme` | iOS app target. |
| `{{APP_TARGET_MACOS}}` | `Acme for Mac` | macOS app target. |
| `{{PRODUCT_ACCENT_TOKEN}}` | `acme` | Product-branded token name on `AppTheme.Colors`. |
| `{{EXTERNAL_STYLE_SDK}}` | `StyleTheme` | External styling SDK wrapped inside `AppTheme` (if any). |

`PreviewHost` is the canonical, non-templatized name of the TCA-free preview target
(see [`../architecture.md`](../architecture.md) SW-2/SW-5).

---

## What `Design/` is for

- **Domain-less, reusable SwiftUI**: buttons, cards, glass surfaces, type styles, color tokens, iconography.
- Plain SwiftUI. **No** `ComposableArchitecture` import. No `@Dependency`. No `Action` / `State`. (SW-5, UZF-5)
- Snapshot-testable in isolation; no app state required to render.
- **Target membership: {{APP_TARGET_IOS}} + {{APP_TARGET_MACOS}} + PreviewHost** — same as a `<Name>View.swift`. The PreviewHost target compiles all of `Design/`.

## `Design/` vs. `<Name>View.swift` — both are TCA-free, what's the difference?

| | `Design/` (Components) | `App/Pages/<X>/<X>View.swift` |
| --- | --- | --- |
| Knows about domain types (`Endeavor`, `Profile`) | ❌ | ✅ |
| Reused across ≥ 2 features | ✅ | typically no (use Fragments instead) |
| File name | no suffix (e.g. `GlassCard.swift`) | `…View.swift` |
| TCA-free | ✅ | ✅ |
| PreviewHost target | ✅ | ✅ |
| ≥ 3 `#Preview` blocks | ✅ | ✅ |

The shared property — both compile under PreviewHost — is why we can iterate on UI without booting a Store. A domain-bound reusable view is a **Fragment**, not a Component (UZF-5).

## What `Design/` is NOT

- ❌ A home for `Profile`, `Endeavor`, or any other domain type.
- ❌ A home for one-off views used by exactly one feature (those become subviews of the `<Name>View.swift` or live in `App/Pages/<Name>/Subviews/`).
- ❌ A home for `…Fragment` types — Fragments are domain-specific.

## `AppTheme`

```swift
public enum AppTheme {
    public enum Colors {
        public static let surface = Color("surface")
        public static let foreground = Color("foreground")
        public static let accent = Color("accent")
        public static let warning = Color("warning")
        public static let danger = Color("danger")
        public static let complementaryA = Color("complementaryA")
        // …
    }
    public enum Typography {
        public static let title = Font.title.weight(.semibold)
        public static let body = Font.body
        public static let caption = Font.caption
    }
    public enum Spacing {
        public static let tiny: CGFloat = 4
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 16
        public static let large: CGFloat = 24
    }
    public enum Radius {
        public static let card: CGFloat = 12
        public static let pill: CGFloat = .infinity
    }
}
```

- All colors are asset-catalog-backed so they react to system color scheme.
- No magic numbers in Screen / View / Fragment code — they read from `AppTheme.Spacing.medium`, etc.
- If a value is used in exactly one place, it's allowed to inline; if used in ≥ 2 places, promote to `AppTheme`.

## Bridging external design packages

If the project depends on an external styling SDK (Material, custom in-house package), wrap it inside `AppTheme` rather than letting Views/Screens import the SDK directly. This keeps the design surface stable when the underlying package updates.

```swift
// App/Theme/AppTheme+External.swift
extension AppTheme.Colors {
    public static let {{PRODUCT_ACCENT_TOKEN}} = {{EXTERNAL_STYLE_SDK}}.palette.primary   // wraps external palette
}
```

Views still read `AppTheme.Colors.{{PRODUCT_ACCENT_TOKEN}}`. The external dependency lives in one file.

## Components — example shape

```swift
// Design/Cards/GlassCard.swift
public struct GlassCard<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }

    public var body: some View {
        content
            .padding(AppTheme.Spacing.medium)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }
}

#Preview("light")  { GlassCard { Text("Sample") }.padding() }
#Preview("dark")   { GlassCard { Text("Sample") }.padding().preferredColorScheme(.dark) }
#Preview("long")   { GlassCard { Text(String(repeating: "Long ", count: 50)) }.padding() }
```

Three previews here too: typical / dark / inconvenient (overflowing) — matched 1:1 by snapshot tests (UZF-18, SW-17). Glass-backed Components opt into `liquidGlassFallback()` in their snapshot tests (see [`07-testing.md`](07-testing.md)).

## Components and accessibility

- Every interactive Component declares `.accessibilityLabel`, `.accessibilityValue`, `.accessibilityAction` as appropriate.
- A Component never *defaults* a color that can't satisfy WCAG AA. Pick from `AppTheme.Colors` and trust the palette.
