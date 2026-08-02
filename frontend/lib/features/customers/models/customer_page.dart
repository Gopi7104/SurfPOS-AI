import 'customer_model.dart';

/// One page of [CustomerRepository.listCustomers] — mirrors
/// `InventoryPage`'s cursor-pagination shape so a future backend-backed
/// `CustomerRepositoryImpl` can return the exact same shape without any
/// caller (controller or widget) changing.
class CustomerPage {
  const CustomerPage({required this.items, required this.nextCursor});

  final List<CustomerModel> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}
