# features/dashboard/

The Merchant Dashboard — the app's home screen (Phase 1, see docs/22_DEVELOPMENT_ROADMAP.md).
Reads the caller's Firebase-tracked merchant application plus a live Surfboard Merchant/Store
profile once those ids exist; shows Today's Business Summary (zero placeholders — Billing isn't
implemented yet), Quick Actions, Recent Activity (empty state), and System Status.

Deviates from the general `data/domain/presentation` shape used elsewhere in `features/` — this
folder uses the flatter, explicitly-requested Phase 1 structure instead:

```
dashboard/
├── models/         # MerchantProfileModel, StoreProfileModel, BusinessSummary, DashboardState
├── repositories/   # DashboardRepository (interface) + impl — composes /merchant/applications,
│                   # /merchant, /stores/:id into one DashboardState
├── controllers/    # DashboardController (AsyncNotifier<DashboardState>)
├── providers/      # Riverpod DI wiring
├── widgets/        # Reusable pieces: DashboardCard, StatusChip, MerchantInfoTile,
│                   # QuickActionCard, SectionHeader, DashboardSummaryStatCard, DashboardLoadingSkeleton
└── pages/          # DashboardPage — assembles the above; hosted inside the app shell
                    # (see lib/app/main_shell_page.dart), not routed to directly
```

Billing, Inventory, Reports, and Settings tabs are placeholder screens in their own feature
folders (`features/billing/`, `features/inventory/`, `features/analytics/`, `features/settings/`)
until a later phase is approved.
