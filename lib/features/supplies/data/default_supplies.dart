import 'supply_item.dart';

/// Starter catalog of universal kost essentials (name EN, name ID).
/// Starts with realistic essentials so new users aren't overwhelmed by items they don't own.
const defaultSupplies = <SupplyItem>[
  // Bathroom
  SupplyItem(id: 'b1', name: 'Bath soap', nameId: 'Sabun mandi', category: SupplyCategory.bathroom),
  SupplyItem(id: 'b2', name: 'Shampoo', nameId: 'Sampo', category: SupplyCategory.bathroom),
  SupplyItem(id: 'b3', name: 'Toothpaste', nameId: 'Pasta gigi', category: SupplyCategory.bathroom),
  SupplyItem(
    id: 'b5',
    name: 'Laundry detergent',
    nameId: 'Deterjen',
    category: SupplyCategory.bathroom,
    status: SupplyStatus.low, // Pre-populates shopping list to introduce restock workflow
  ),
  // Household
  SupplyItem(id: 'h1', name: 'Dish soap', nameId: 'Sabun cuci piring', category: SupplyCategory.household),
  SupplyItem(id: 'h2', name: 'Tissue', nameId: 'Tisu', category: SupplyCategory.household),
  SupplyItem(id: 'h3', name: 'Trash bags', nameId: 'Kantong sampah', category: SupplyCategory.household),
  // First Aid
  SupplyItem(id: 'p1', name: 'Medicated oil', nameId: 'Minyak angin', category: SupplyCategory.firstAid),
  // Food & Drinks
  SupplyItem(id: 'f4', name: 'Coffee & tea', nameId: 'Kopi & teh', category: SupplyCategory.food),
  SupplyItem(id: 'f2', name: 'Instant noodles', nameId: 'Mie instan', category: SupplyCategory.food),
];
