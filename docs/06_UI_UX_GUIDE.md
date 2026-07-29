# 06 — UI/UX Guide

> **Reviewed during the Surfboard-alignment documentation pass — unaffected in substance.** This design system is agnostic to which backend system of record answers a given screen's data (see [02_ARCHITECTURE.md § 4](02_ARCHITECTURE.md#4-data-ownership-surfboard-vs-firebase)); only new Settings sub-sections were added (§ 8) for the new Store Capabilities/Device/Branding features. Prerequisite reading: [01_PROJECT_OVERVIEW.md](01_PROJECT_OVERVIEW.md), [05_FEATURES.md](05_FEATURES.md). Related: [07_CODING_RULES.md](07_CODING_RULES.md) for Flutter code conventions.

---

## 1. Design Philosophy

SurfPOS AI is used **one-handed, at a counter, often in a hurry**. Every design decision optimizes for:

- **Speed over decoration.** A cashier should never wait on an animation to complete an action.
- **Thumb-reachable primary actions.** Checkout, confirm, and scan buttons live in the bottom half of the screen.
- **High legibility in variable lighting** (shops are often bright, sometimes dim) — strong contrast, no low-contrast gray-on-white text.
- **Forgiving of interruption.** A cashier may be interrupted mid-sale by a customer or a phone call; state must persist and resume cleanly.

## 2. Color Palette

A neutral, retail-appropriate palette with a single accent used consistently for primary actions. (Treat hex values below as the placeholder brand palette — swap for final brand colors before public launch, keeping the same *roles*.)

| Role | Color | Hex | Usage |
|---|---|---|---|
| Primary / Brand | Ocean Blue | `#0A6E8C` | Primary buttons, active nav state, links |
| Primary Dark | Deep Ocean | `#074E63` | Pressed states, headers |
| Accent / Success | Sea Green | `#1B9C6E` | Success states, completed sales, positive analytics |
| Warning | Amber | `#E0A800` | Low stock, pending review, caution states |
| Danger | Coral Red | `#D64545` | Errors, out-of-stock, destructive actions |
| Neutral 900 | `#161B21` | Primary text |
| Neutral 600 | `#5B6572` | Secondary text |
| Neutral 300 | `#D8DCE1` | Borders, dividers |
| Neutral 100 | `#F4F6F8` | Screen background |
| Surface | `#FFFFFF` | Cards, sheets |

**Dark mode:** supported from Phase 1 as a system-following theme (not a manual toggle initially — see [10_TASKS.md](10_TASKS.md) for when a manual toggle is scheduled). Dark-mode surface = `#12161B`, dark background = `#0B0E12`, text/border roles invert appropriately while brand/accent hues stay the same for recognizability.

**Rule:** Color alone is never the only signal for status (accessibility) — every colored status also carries an icon or label (e.g. low stock = amber dot **and** "Low Stock" text).

## 3. Typography

- **Typeface:** A single geometric/humanist sans-serif family bundled with the app (e.g. Inter or the platform default if a licensed font isn't selected yet — record the final choice in [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md)). Do not mix font families.
- **Scale** (mobile, logical pixels):

| Style | Size | Weight | Usage |
|---|---|---|---|
| Display | 28 | Bold | Rare — big totals (e.g. checkout grand total) |
| H1 | 22 | Bold | Screen titles |
| H2 | 18 | SemiBold | Section headers, card titles |
| Body | 15 | Regular | Default body text |
| Body Strong | 15 | SemiBold | Emphasized body text, list item titles |
| Caption | 12 | Regular | Timestamps, helper text |
| Button | 15 | SemiBold | All button labels |

- **Minimum tappable text size:** never below 12px; numeric prices/quantities in lists never below 14px.

## 4. Spacing

8-point grid system. All margins/padding are multiples of 8 (with 4 permitted only for icon-to-label gaps).

| Token | Value | Usage |
|---|---|---|
| `xs` | 4px | Icon-to-label gaps |
| `sm` | 8px | Compact internal padding |
| `md` | 16px | Standard screen margin, card padding |
| `lg` | 24px | Section separation |
| `xl` | 32px | Major screen-section breaks |

- **Screen horizontal margin:** 16px standard.
- **Minimum tappable target:** 48x48 logical pixels (matches platform accessibility guidance) — applies to every icon button, list row action, and checkbox.

## 5. Icons

- Single icon set throughout (Material Symbols recommended for Flutter — consistent with Flutter's native widget language, reducing custom-asset maintenance).
- Icons are always paired with a text label in navigation and primary actions; icon-only buttons are reserved for well-understood, high-frequency actions (back, close, scan, search) and must have a `tooltip`/semantic label for accessibility.
- Stroke weight and size stay consistent within a screen (don't mix a bold nav icon with thin inline icons).

## 6. Cards

- Standard card: white/surface background, 12px corner radius, subtle elevation (2dp) or 1px `Neutral 300` border in flat/dark contexts — pick one elevation strategy per theme and apply consistently (don't mix shadow and border styles on the same screen).
- Card internal padding: 16px (`md`).
- Dashboard/insight cards: leading icon + title + optional trailing action, body content below.
- List-item "cards" (products, sales) may be flatter (divider-separated rows) rather than boxed cards, to fit more rows per screen — reserve true elevated cards for Dashboard summary content.

## 7. Animations

- **Purposeful only.** Animate to communicate state change (item added to cart, sale completed, scan detected), never for decoration.
- **Duration:** 150–250ms for micro-interactions (button press, card expand), 300–400ms max for screen transitions. Nothing blocks input for longer than the animation itself.
- **Standard transitions:** shared-axis / fade-through for screen-to-screen navigation (Flutter's Material motion patterns); a scan-success screen may use a brief (≤500ms) checkmark animation, but the underlying action (adding to cart) must already be complete before the animation starts — animation reflects a completed action, it never gates one.
- **Loading states:** skeleton placeholders for content that takes >300ms to load (product lists, dashboard); a spinner only for indeterminate short waits (<2s); a progress/status indicator with text for anything longer (e.g. "Processing invoice scan…").

## 8. Navigation

- **Bottom navigation bar** (3–5 top-level destinations): Dashboard, Billing, Inventory, Reports, Settings (Scanner is reached from within Billing/Inventory, not a separate tab, since it's an input method rather than a destination). Settings now also contains Store Capabilities/Payment Methods, Devices, and Branding sub-sections (see [05_FEATURES.md §§ 14–16](05_FEATURES.md#14-store-capabilities--payment-methods)) — these remain sub-sections of Settings, not new top-level nav destinations, to keep the nav bar within the 3–5 item limit.
- **Role-based visibility:** staff accounts may see a reduced nav set (e.g. no Settings) per [05_FEATURES.md § 2 Authentication](05_FEATURES.md#2-authentication) future permission model.
- **Deep, task-focused flows** (checkout, invoice scan review, onboarding) use a **full-screen modal/stack** with an explicit back/close and no bottom nav visible — signaling "you're in a task, not browsing."
- **Back behavior:** Android hardware/gesture back always mirrors the in-app back button; never trap the user without an exit.

## 9. Design System (Component Inventory)

Baseline reusable widget set every screen composes from (see [07_CODING_RULES.md § Folder Conventions](07_CODING_RULES.md#3-folder-conventions) for where these live in `lib/core/widgets/`):

- `PrimaryButton` / `SecondaryButton` / `DestructiveButton`
- `AppCard`
- `StatusBadge` (color + icon + label, per §2 accessibility rule)
- `AppTextField` (with built-in validation error slot)
- `EmptyState` (icon + message + optional CTA — used whenever a list is empty, never a bare blank screen)
- `AppLoadingIndicator` / `AppSkeleton`
- `ConfirmationSheet` (bottom sheet for destructive/important confirmations — e.g. rejecting an invoice scan, cancelling a sale)
- `ReceiptPreview`
- `InsightCard`

**Rule:** a new screen should be buildable almost entirely from this inventory. A one-off custom widget is a signal to check whether it should instead be added to the shared inventory (see [07_CODING_RULES.md](07_CODING_RULES.md)).

## 10. Responsive Rules

- **Primary target:** phones, portrait orientation, 360–430 logical-pixel width.
- **Tablet support:** layouts must not break above phone width (use `LayoutBuilder`/`MediaQuery` breakpoints), but tablet-optimized multi-column layouts are Future Scope, not Phase 1 (see [10_TASKS.md](10_TASKS.md)).
- **Landscape:** billing/checkout screens should remain usable in landscape (common when a phone is mounted at a counter), but landscape optimization is secondary to portrait.
- **Text scaling:** respect system font-scale accessibility settings up to at least 130% without clipped text — test critical screens (Billing, Checkout) at large text scale.

## 11. Flutter Widget Guidelines

- Prefer **`const` constructors** wherever the widget tree allows, for rebuild performance (see [07_CODING_RULES.md § Performance](07_CODING_RULES.md#10-performance)).
- Screens are composed from small, named widgets (one visual concern each) rather than one large `build()` method — see the component-size limits in [07_CODING_RULES.md § Component Size Limits](07_CODING_RULES.md#4-component-size-limits).
- Use `Theme.of(context)` / a centralized `AppTheme` for all colors/text styles — **never hard-code a hex color or font size inline in a widget.** All values in §§2–4 above must be defined once in `lib/core/theme/` and referenced everywhere.
- Use `go_router`'s declarative routes for all navigation (no ad-hoc `Navigator.push` with inline route widgets) — see [02_ARCHITECTURE.md § 2](02_ARCHITECTURE.md#2-frontend-flutter).

---

**Next:** [07_CODING_RULES.md](07_CODING_RULES.md) — the permanent coding rules for every future contribution.
