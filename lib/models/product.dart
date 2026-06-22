class Product {
  final String id;
  final ProductType type;

  const Product({required this.id, required this.type});

  String get title => id.replaceAll('_', ' ');

  String get priceLabel {
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(id);
    return match == null ? '' : '${match.group(1)} جنيه';
  }
}

enum ProductType { fakka, mared }

const fakkaProducts = [
  'Fakka_2.5_Unite',
  'Fakka_4.25_Unite',
  'Fakka_5_Unite',
  'Fakka_6_NewUnite',
  'Fakka_7_Unite',
  'Fakka_9_Unite',
  'Fakka_10_Unite',
  'Fakka_10_NewUnite',
  'Fakka_10.5_Unite',
  'Fakka_11.5_Unite',
  'Fakka_12_Unite',
  'Fakka_12.5_Unite',
  'Fakka_13_Unite',
  'Fakka_13.5_Unite',
  'Fakka_15_Unite',
  'Fakka_15_NewUnite',
  'Fakka_15.5_Unite',
  'Fakka_16.5_Unite',
  'Fakka_17.5_Unite',
  'Fakka_19.5_NewUnite',
  'Fakka_20_Unite',
  'Fakka_26_Unite',
];

const maredProducts = [
  'Mared_10_Minuts',
  'Mared_10_Flexs',
  'Mared_10_Social',
];

final allProducts = [
  ...fakkaProducts.map((id) => Product(id: id, type: ProductType.fakka)),
  ...maredProducts.map((id) => Product(id: id, type: ProductType.mared)),
];
