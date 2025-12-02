import 'package:cloud_firestore/cloud_firestore.dart';

/// Define los segmentos de clientes para el CRM.
enum CustomerSegment {
  schools, // Colegios/Docentes
  companies, // Empresas
  families, // Familias/Adultos
  unknown, // Segmento por defecto o en caso de error
}

/// Representa a un cliente en la base de datos de Firestore (CRM).
/// Corresponde al requerimiento C1.
class CustomerModel {
  final String id;
  final String name; // Nombre del colegio, empresa o familia
  final CustomerSegment segment;
  final String? contactPerson; // Persona de contacto (opcional)
  final String email;
  final String? phone;
  final String? address;
  final Timestamp createdAt;

  CustomerModel({
    required this.id,
    required this.name,
    required this.segment,
    this.contactPerson,
    required this.email,
    this.phone,
    this.address,
    required this.createdAt,
  });

  /// Convierte la instancia de [CustomerModel] a un mapa para Firestore.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      // Guardamos el segmento como un string legible.
      'segment': segment.name,
      'contactPerson': contactPerson,
      'email': email,
      'phone': phone,
      'address': address,
      'createdAt': createdAt,
    };
  }

  /// Crea una instancia de [CustomerModel] desde un [DocumentSnapshot] de Firestore.
  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Convierte el string del segmento a nuestro enum CustomerSegment.
    CustomerSegment segment;
    switch (data['segment']) {
      case 'schools':
        segment = CustomerSegment.schools;
        break;
      case 'companies':
        segment = CustomerSegment.companies;
        break;
      case 'families':
        segment = CustomerSegment.families;
        break;
      default:
        segment = CustomerSegment.unknown;
    }

    return CustomerModel(
      id: doc.id,
      name: data['name'] ?? '',
      segment: segment,
      contactPerson: data['contactPerson'], // Puede ser null
      email: data['email'] ?? '',
      phone: data['phone'], // Puede ser null
      address: data['address'], // Puede ser null
      // Si createdAt no existe, usa la fecha y hora actual.
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}