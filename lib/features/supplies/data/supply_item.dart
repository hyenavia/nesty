enum SupplyStatus { safe, low, out }

enum SupplyCategory { food, bathroom, firstAid, household }

class SupplyItem {
  const SupplyItem({
    required this.id,
    required this.name,
    this.nameId,
    required this.category,
    this.status = SupplyStatus.safe,
    this.quantity,
  });

  final String id;
  final String name; // English (or user-typed) name
  final String? nameId; // optional Indonesian name
  final SupplyCategory category;
  final SupplyStatus status;
  final int? quantity; // optional pieces left; null = not counted

  /// Items that are Running low / Out are on the shopping list automatically.
  bool get needsRestock => status != SupplyStatus.safe;

  String displayName(String lang) =>
      (lang == 'id' && nameId != null) ? nameId! : name;

  SupplyItem copyWith({
    SupplyStatus? status,
    int? quantity,
    bool clearQuantity = false,
  }) =>
      SupplyItem(
        id: id,
        name: name,
        nameId: nameId,
        category: category,
        status: status ?? this.status,
        quantity: clearQuantity ? null : (quantity ?? this.quantity),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameId': nameId,
        'category': category.name,
        'status': status.name,
        'quantity': quantity,
      };

  factory SupplyItem.fromJson(Map<String, dynamic> json) => SupplyItem(
        id: json['id'] as String,
        name: json['name'] as String,
        nameId: json['nameId'] as String?,
        category: SupplyCategory.values.byName(json['category'] as String),
        status: SupplyStatus.values.byName(json['status'] as String),
        quantity: (json['quantity'] as num?)?.toInt(),
      );
}
