import 'supply_item.dart';

/// Starter catalog of kost essentials (name EN, name ID).
const defaultSupplies = <SupplyItem>[
  // Food & Drinks
  SupplyItem(id: 'f1', name: 'Rice', nameId: 'Beras', category: SupplyCategory.food),
  SupplyItem(id: 'f2', name: 'Instant noodles', nameId: 'Mie instan', category: SupplyCategory.food),
  SupplyItem(id: 'f3', name: 'Eggs', nameId: 'Telur', category: SupplyCategory.food),
  SupplyItem(id: 'f4', name: 'Coffee & tea', nameId: 'Kopi & teh', category: SupplyCategory.food),
  SupplyItem(id: 'f5', name: 'Cooking oil', nameId: 'Minyak goreng', category: SupplyCategory.food),
  SupplyItem(id: 'f6', name: 'Sauces', nameId: 'Saus & kecap', category: SupplyCategory.food),
  // Bathroom
  SupplyItem(id: 'b1', name: 'Bath soap', nameId: 'Sabun mandi', category: SupplyCategory.bathroom),
  SupplyItem(id: 'b2', name: 'Shampoo', nameId: 'Sampo', category: SupplyCategory.bathroom),
  SupplyItem(id: 'b3', name: 'Toothpaste', nameId: 'Pasta gigi', category: SupplyCategory.bathroom),
  SupplyItem(id: 'b4', name: 'Face wash', nameId: 'Sabun cuci muka', category: SupplyCategory.bathroom),
  SupplyItem(id: 'b5', name: 'Laundry detergent', nameId: 'Deterjen', category: SupplyCategory.bathroom),
  SupplyItem(id: 'b6', name: 'Fabric softener', nameId: 'Pewangi pakaian', category: SupplyCategory.bathroom),
  // First Aid
  SupplyItem(id: 'p1', name: 'Medicated oil', nameId: 'Minyak angin', category: SupplyCategory.firstAid),
  SupplyItem(id: 'p2', name: 'Paracetamol', nameId: 'Paracetamol', category: SupplyCategory.firstAid),
  SupplyItem(id: 'p3', name: 'Antacid', nameId: 'Obat maag', category: SupplyCategory.firstAid),
  SupplyItem(id: 'p4', name: 'Plasters', nameId: 'Plester luka', category: SupplyCategory.firstAid),
  // Household
  SupplyItem(id: 'h1', name: 'Dish soap', nameId: 'Sabun cuci piring', category: SupplyCategory.household),
  SupplyItem(id: 'h2', name: 'Tissue', nameId: 'Tisu', category: SupplyCategory.household),
  SupplyItem(id: 'h3', name: 'Trash bags', nameId: 'Kantong sampah', category: SupplyCategory.household),
];
