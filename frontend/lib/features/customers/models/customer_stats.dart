/// Customer Statistics section's 6 cards — mirrors `InventoryStats`'s
/// record-typedef shape.
typedef CustomerStats = ({
  int totalCustomers,
  int newThisMonth,
  int activeCustomers,
  int vipCustomers,
  double averageSpend,
  double averageOrders,
});

const emptyCustomerStats = (
  totalCustomers: 0,
  newThisMonth: 0,
  activeCustomers: 0,
  vipCustomers: 0,
  averageSpend: 0.0,
  averageOrders: 0.0,
);
