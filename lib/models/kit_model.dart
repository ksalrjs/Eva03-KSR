import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa un componente individual dentro de un Kit.
/// Contiene la referencia al producto y la cantidad necesaria.
class KitComponent {
  /// ID del documento del producto en la colección 'products'.
  final String productId;

  /// Cantidad de este producto que se necesita para armar un kit.
  final int quantity;

  KitComponent({
    required this.productId,
    required this.quantity,
  });

  /// Convierte el objeto [KitComponent] a un mapa para guardarlo en Firestore.
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
    };
  }

  /// Crea una instancia de [KitComponent] desde un mapa (obtenido de Firestore).
  factory KitComponent.fromMap(Map<String, dynamic> map) {
    return KitComponent(
      productId: map['productId'] ?? '',
      quantity: map['quantity'] ?? 0,
    );
  }
}

/// Representa un Kit, que es un conjunto de productos individuales.
/// Corresponde al requerimiento A3.
class KitModel {
  final String id;
  final String name;
  final String sku;
  final String category;
  final double salePrice; // Precio de venta del Kit
  final List<KitComponent> components;

  KitModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.salePrice,
    required this.components,
  });

  /// Convierte la instancia de [KitModel] a un mapa para Firestore.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sku': sku,
      'category': category,
      'salePrice': salePrice,
      // Convertimos cada componente a su formato JSON.
      'components': components.map((c) => c.toJson()).toList(),
    };
  }

  /// Crea una instancia de [KitModel] desde un [DocumentSnapshot] de Firestore.
  factory KitModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return KitModel(
      id: doc.id,
      name: data['name'] ?? '',
      sku: data['sku'] ?? '',
      category: data['category'] ?? '',
      salePrice: (data['salePrice'] ?? 0.0).toDouble(),
      // Si 'components' existe, lo mapeamos para crear la lista de objetos KitComponent.
      components: (data['components'] as List<dynamic>?)
              ?.map((componentData) => KitComponent.fromMap(componentData))
              .toList() ??
          [],
    );
  }
}