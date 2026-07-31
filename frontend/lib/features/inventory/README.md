# features/inventory/

Product catalog CRUD, search/filter/sort, pagination, and soft delete (Phase 2, see
docs/22_DEVELOPMENT_ROADMAP.md). Stock quantity is hydrated per-product from a separate per-store
stock record the backend owns (`backend/src/modules/inventory/stock.repository.js`,
docs/08_ARCHITECTURE_DECISIONS.md § ADR-024) — this feature only ever reads/writes it through
`GET/PATCH /inventory/products(...)`, never directly.

Follows the same flat structure `features/dashboard/` established in Phase 1 (not the older
`data/domain/presentation` shape used elsewhere in `features/`):

```
inventory/
├── models/         # ProductModel (read), ProductDraft (create/update payload), ProductStatus,
│                   # InventoryQuery/StockFilter/InventorySortOption, InventoryPage, InventoryFailure
├── repositories/   # InventoryRepository (interface) + impl — wraps /inventory/products(...)
├── controllers/    # InventoryListController (paginated search/filter/sort state),
│                   # InventoryFormController (Add/Edit submission state)
├── providers/      # Riverpod DI wiring — every controller is `.autoDispose.family<..., String>`
│                   # keyed by Firebase uid (see docs/22_DEVELOPMENT_ROADMAP.md, cross-user
│                   # isolation fix) — never a global singleton
├── widgets/        # ProductCard, InventoryFilterBar, ProductForm (shared by Add + Edit)
└── pages/          # InventoryHomePage (tab root — stats + quick actions), ProductListPage,
                    # AddProductPage, EditProductPage, ProductDetailsPage, CategoriesPage
```

Reuses `core/widgets/{cards/section_card,headers/section_header,chips/status_chip}.dart` (moved
there from `features/dashboard/widgets/` in this same pass, per docs/07_CODING_RULES.md § 8) and
`core/widgets/text_fields/app_search_field.dart`/`core/widgets/loading/skeleton_list.dart`
(already built generically enough for this feature to use as-is).
