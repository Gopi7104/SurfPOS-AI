/// Customer Statistics section's 6 cards — mirrors `InventoryStats`'s
/// record-typedef shape.
typedef CustomerStats = ({
  int totalCustomers,
  int newThisMonth,
  int activeCustomers,
  int vipCustomers,
  double averageSpend,
  double averageOrders,
  // Phase CRM-1 additions — power the List page's "Returning Customers",
  // "Inactive Customers", and "Lifetime Revenue" KPI tiles, which existed in
  // the layout already but had no value wired to them (see
  // `CustomerRepositoryImpl.getStats`, the only place these are computed,
  // using the same `computeCustomerSegments` every other segment view uses).
  int returningCustomers,
  int inactiveCustomers,
  double lifetimeRevenue,
});

const emptyCustomerStats = (
  totalCustomers: 0,
  newThisMonth: 0,
  activeCustomers: 0,
  vipCustomers: 0,
  averageSpend: 0.0,
  averageOrders: 0.0,
  returningCustomers: 0,
  inactiveCustomers: 0,
  lifetimeRevenue: 0.0,
);
