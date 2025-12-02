import 'package:cloud_firestore/cloud_firestore.dart';


class ProductModel {
  /// El ID único del documento en Firestore.
  final String id;

  /// Nombre del producto.
  final String name;

  /// Código de Identidad único (SKU).
  final String sku;

  /// Nombre del proveedor.
  final String supplier;

  /// Valor de compra (costo interno).
  final double purchasePrice;

  /// Categoría a la que pertenece (Lenguaje, Matemática, etc.).
  final String category;

  /// Cantidad disponible en stock.
  final int stock;

  /// Nivel mínimo de stock para generar alertas.
  final int minStockLevel;

  ProductModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.supplier,
    required this.purchasePrice,
    required this.category,
    required this.stock,
    this.minStockLevel = 5, // Valor por defecto
  });

  /// Convierte una instancia de [ProductModel] a un mapa de tipo [Map<String, dynamic>].
  /// Esto es útil para escribir datos en Firestore.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sku': sku,
      'supplier': supplier,
      'purchasePrice': purchasePrice,
      'category': category,
      'stock': stock,
      'minStockLevel': minStockLevel,
    };
  }

  /// Crea una instancia de [ProductModel] a partir de un [DocumentSnapshot] de Firestore.
  /// Esto nos permite leer los datos de la base de datos y convertirlos en un objeto Dart.
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      sku: data['sku'] ?? '',
      supplier: data['supplier'] ?? '',
      // Aseguramos que el precio sea un double, con 0.0 como valor por defecto.
      purchasePrice: (data['purchasePrice'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      // Aseguramos que el stock sea un int, con 0 como valor por defecto.
      stock: data['stock'] ?? 0,
      minStockLevel: data['minStockLevel'] ?? 5,
    );
  }

  /// Crea una copia de la instancia actual con la posibilidad de modificar algunos campos.
  /// Muy útil para la gestión de estado.
  ProductModel copyWith({int? stock, int? minStockLevel}) {
    return ProductModel(
      id: id,
      name: name,
      sku: sku,
      supplier: supplier,
      purchasePrice: purchasePrice,
      category: category,
      stock: stock ?? this.stock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
    );
  }
}