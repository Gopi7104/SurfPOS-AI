/// Preset tags every merchant can apply — [CustomerModel.tags] also accepts
/// any custom string beyond these, so this is a set of suggestions/well-
/// known values (e.g. for [isVip] checks), never an exhaustive enum.
abstract final class CustomerTags {
  static const vip = 'VIP';
  static const wholesale = 'Wholesale';
  static const regular = 'Regular';
  static const business = 'Business';
  static const staff = 'Staff';

  static const presets = [vip, wholesale, regular, business, staff];
}
