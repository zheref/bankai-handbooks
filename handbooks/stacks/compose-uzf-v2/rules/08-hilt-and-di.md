<!-- Canonical source: zheref/bankai-handbooks. Consumer repos carry a generated, pinned, per-surface mirror of this file (CON-13) -- never hand-edit the mirror; change it here. -->

# 08 — Hilt & Dependency Injection

## Repo-specific placeholders

- `{{PROJECT_NAME}}` — the product/app name, used as the prefix of the `@HiltAndroidApp` Application class (`{{PROJECT_NAME}}Application`) and the Room `@Database` type (`{{PROJECT_NAME}}Database`). Illustrative example: `Acme`.

(Module file names in the tree below — `RetrofitModule`, `RoomModule`, `PreferencesModule`, `RemoteDataModule`, `FeatureFlagsModule` — and the Service names they bind are **illustrative**, not repo config. `Hilt`, `Retrofit`, `Room`, `SingletonComponent`, `@Binds`, `@Provides`, etc. are stack/framework API names and are never tokenized: this stack is **Compose + Hilt**, so Hilt is fixed the way TCA is fixed on the SwiftUI stack.)

---

Dependency injection is how the Compose UZF stack satisfies `UZF-16` (every external system sits behind a DI'd Service interface with a stub) on Android. Hilt is the injector. This file introduces the Compose-stack DI rules **KT-23** (bootstrap), **KT-17** (module layering), **KT-24** (binding conventions), **KT-3** (Feature injection), and **KT-25** (DI anti-patterns).

## Bootstrapping Hilt (KT-23)

- `@HiltAndroidApp class {{PROJECT_NAME}}Application : Application()` is **required**. Not commented out, not deferred behind a flag, not "added later." The manifest's `android:name` points at it from day one; without it no `@Inject` resolves.
- A **single `@AndroidEntryPoint` Activity hosts the entire Compose tree.** Do not sprinkle `@AndroidEntryPoint` per screen — screens are Composables, not Android entry points. Additional entry points exist only for genuinely separate Android components (a widget, a `Service`, a `BroadcastReceiver`), never per feature.

## Module organization — by layer (KT-17)

```
library/di/                      # Cross-cutting infrastructure modules
    RetrofitModule.kt            # OkHttpClient, Retrofit, Json converter
    RoomModule.kt                # {{PROJECT_NAME}}Database + every @Dao
    PreferencesModule.kt         # SharedPreferences + Preferences Service binding
    RemoteDataModule.kt          # backend / remote-objects Service binding
    FeatureFlagsModule.kt        # feature-flags Service binding
features/<feature>/
    <Feature>Module.kt           # @Binds for this feature's Services + @Provides for its Producer deps
```

- **Cross-cutting infrastructure** (network, database, preferences, backend client, feature flags) lives in `library/di/`. This is the shared plumbing every feature draws on — Retrofit/OkHttp, the Room `{{PROJECT_NAME}}Database` and its `@Dao`s, `SharedPreferences`, the remote-data client.
- **Feature-specific bindings live next to the feature** as one module per feature folder, named `<Feature>Module.kt`. Deleting a feature therefore deletes its entire DI footprint — no orphaned bindings left behind in a central module.
- Prefer **one Hilt module per feature folder**; do not merge several features' bindings into a single god-module, and do not push a feature's private Service binding up into `library/di/`.

## Binding conventions (KT-24)

- Use `@InstallIn(SingletonComponent::class)` for application-scoped singletons. Narrower components (`ViewModelComponent`, `ActivityRetainedComponent`) only when a binding genuinely must not outlive that scope.
- Use `@Binds` for interface → implementation bindings — **preferred over `@Provides`.** Reserve `@Provides` for types you must actively construct (third-party objects, builders, configured instances) where there is no interface-to-impl mapping to express.
- `@Singleton` **only when sharing the instance is required** (a connection pool, an in-flight-token cache, the Room database). **Default to unscoped** — a fresh instance per injection is cheaper to reason about and never leaks state between features.
- Each `@Provides` and `@Binds` declaration is annotated to make its **lifetime explicit** at the binding site. A reader should see the scope without chasing the component definition.
- This is where the UZF service tier is wired (`UZF-16`): a `Live<Name>Service` is bound to its `interface <Name>Service` with `@Binds`; Producers are injected `class <Name>Producer @Inject constructor(...)`; DI-registered Mappers (`toDomain` / `fromDomain` / `toException`) are provided here too. The `Stubbed<Name>Service` variant is swapped in for tests via `@TestInstallIn` (see KT-24), never bound in the production module.

## Feature (ViewModel) injection (KT-3)

- Every Feature is `@HiltViewModel class <Feature>Feature @Inject constructor(...)`. Its Producers, Services, Mappers, and Providers all arrive through that constructor. A Feature that derives from a shared `Feature<State, Event, UiEffect>` base is still annotated `@HiltViewModel` on the concrete subclass.
- Screens obtain the Feature with `hiltViewModel<<Feature>Feature>()` — **never `viewModel()`** and **never `remember { … }`.** `hiltViewModel()` gives correct `ViewModelStoreOwner` scoping and lets Hilt supply the constructor dependencies; the other two bypass DI and produce an unscoped, dependency-less instance.
- **Test code constructs Features directly** — no Hilt test runner is needed for unit tests. Instantiate `<Feature>Feature(stubbedService, fakeProducer, …)` by hand, passing `Stubbed<Name>Service` and test doubles. Hilt is a production-wiring concern, not a test dependency.

## Forbidden (KT-25)

- **Manual `<Feature>Feature(...)` (or shared-base) instantiation inside a Composable.** Features are always `@HiltViewModel`-injected via `hiltViewModel()`; a `remember { <Feature>Feature() }` in a Composable is a defect.
- **`@Inject` on field declarations** — no field injection in Kotlin. Constructor injection only.
- **Service Locator patterns** — a global `object <Name>ServiceProvider { fun get(): <Name>Service }` reached into from arbitrary code. Dependencies are declared in constructors and resolved by Hilt, not fetched from a static holder.
- **Test Hilt modules that shadow production bindings without `@TestInstallIn(replaces = [...])`.** A test module that silently re-binds a type without declaring what it replaces makes the wiring ambiguous; always name the replaced module.
- **Empty or stub Hilt modules** — a module with no real binding is dead weight. Delete it until it binds something real.
