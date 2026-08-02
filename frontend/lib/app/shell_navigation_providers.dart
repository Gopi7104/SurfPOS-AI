import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lets code outside [MainShellPage]'s own subtree — most notably SurfAI's
/// chat page, which is pushed as a separate route on top of the shell, not
/// one of its `IndexedStack` children — trigger a tab switch or prefill
/// Inventory's search field. `MainShellPage`/`InventoryHomePage` `ref.listen`
/// to these and reset each back to `null` immediately after acting on it, so
/// they're one-shot requests: re-navigating to the same tab twice, or a
/// stale value surviving a rebuild, never re-triggers anything.
///
/// There is no other cross-tree navigation mechanism in this app today (no
/// `go_router`, no shared `GlobalKey<NavigatorState>` — see
/// `docs/08_ARCHITECTURE_DECISIONS.md` ADR-007) — this is intentionally the
/// smallest possible addition rather than introducing one.
final shellTabIndexProvider = StateProvider<int?>((ref) => null);

/// A pending Inventory search query — see [shellTabIndexProvider]'s header
/// comment. Setting this alone does not switch tabs; callers that want
/// "search X" to both open Inventory and prefill the field should set both
/// providers.
final pendingInventorySearchProvider = StateProvider<String?>((ref) => null);
