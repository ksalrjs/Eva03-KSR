import 'package:cloud_firestore/cloud_firestore.dart';

/// Define los posibles estados de una cotización.
enum QuoteStatus {
  draft, // Borrador, aún no enviada.
  sent, // Enviada al cliente.
  accepted, // Aceptada por el cliente.
  rejected, // Rechazada por el cliente.
  unknown, // Estado por defecto o en caso de error.
}

/// Representa un ítem individual (producto o kit) dentro de una cotización.
class QuoteItem {
  final String itemId; // ID del ProductModel o KitModel.
  final String name;
  final int quantity;
  final double unitPrice;

  QuoteItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => quantity * unitPrice;

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  factory QuoteItem.fromMap(Map<String, dynamic> map) {
    return QuoteItem(
      itemId: map['itemId'] ?? '',
      name: map['name'] ?? 'Ítem no encontrado',
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
    );
  }
}

/// Representa una cotización completa.
class QuoteModel {
  final String id;
  final String quoteNumber;
  final String customerId;
  final String customerName; // Denormalizado para fácil acceso.
  final List<QuoteItem> items;
  final double total;
  final QuoteStatus status;
  final Timestamp createdAt;
  final Timestamp? validUntil;

  QuoteModel({
    required this.id,
    required this.quoteNumber,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    this.validUntil,
  });

  Map<String, dynamic> toJson() {
    return {
      'quoteNumber': quoteNumber,
      'customerId': customerId,
      'customerName': customerName,
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'status': status.name,
      'createdAt': createdAt,
      'validUntil': validUntil,
    };
  }

  factory QuoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    QuoteStatus status;
    switch (data['status']) {
      case 'sent':
        status = QuoteStatus.sent;
        break;
      case 'accepted':
        status = QuoteStatus.accepted;
        break;
      case 'rejected':
        status = QuoteStatus.rejected;
        break;
      default:
        status = QuoteStatus.draft;
    }

    return QuoteModel(
      id: doc.id,
      quoteNumber: data['quoteNumber'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? 'Cliente no especificado',
      items: (data['items'] as List<dynamic>?)?.map((itemData) => QuoteItem.fromMap(itemData)).toList() ?? [],
      total: (data['total'] ?? 0.0).toDouble(),
      status: status,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      validUntil: data['validUntil'],
    );
  }
}